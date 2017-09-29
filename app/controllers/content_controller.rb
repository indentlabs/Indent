class ContentController < ApplicationController
  include HasOwnership

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :update, :destroy]

  def index
    @content = content_type_from_controller(self.class)
               .where(user_id: current_user.id)
               .order(:name)

    @content = @content.where(universe: @universe_scope) if @universe_scope.present? && @content.build.respond_to?(:universe)
    @content ||= []
    @questioned_content = @content.sample
    @question = @questioned_content.question unless @questioned_content.nil?

    respond_to do |format|
      format.html { render 'content/index' }
      format.json { render json: @content }
    end
  end

  def show
    content_type = content_type_from_controller(self.class)
    # TODO: Secure this with content class whitelist lel
    @content = content_type.find(params[:id])

    if (current_user || User.new).can_read? @content
      @question = @content.question if current_user.present? and current_user == @content.user

      if current_user
        if @content.updated_at > 30.minutes.ago
          Mixpanel::Tracker.new(Rails.application.config.mixpanel_token).track(current_user.id, 'viewed content', {
            'content_type': content_type.name,
            'content_owner': current_user.present? && current_user.id == @content.user_id,
            'logged_in_user': current_user.present?
          })
        else
          Mixpanel::Tracker.new(Rails.application.config.mixpanel_token).track(current_user.id, 'viewed recently-modified content', {
            'content_type': content_type.name,
            'content_owner': current_user.present? && current_user.id == @content.user_id,
            'logged_in_user': current_user.present?
          })
        end
      end

      respond_to do |format|
        format.html { render 'content/show', locals: { content: @content } }
        format.json { render json: @content }
      end
    else
      if current_user.present?
        return redirect_to :back
      else
        return redirect_to root_path
      end
    end
  end

  def new
    @content = content_type_from_controller(self.class)
               .new

    unless (current_user || User.new).can_create?(content_type_from_controller self.class)
      return redirect_to :back
    end

    respond_to do |format|
      format.html { render 'content/new', locals: { content: @content } }
      format.json { render json: @content }
    end
  end

  def edit
    @content = content_type_from_controller(self.class)
               .find(params[:id])

    unless @content.updatable_by? current_user
      return redirect_to :back
    end

    respond_to do |format|
      format.html { render 'content/edit', locals: { content: @content } }
      format.json { render json: @content }
    end
  end

  def create
    content_type = content_type_from_controller self.class
    initialize_object

    unless current_user.can_create?(content_type)
      return redirect_to :back
    end

    Mixpanel::Tracker.new(Rails.application.config.mixpanel_token).track(current_user.id, 'created content', {
      'content_type': content_type.name
    })

    if @content.save
      if params.key? 'image_uploads'
        upload_files params['image_uploads'], content_type.name, @content.id
      end

      successful_response(content_creation_redirect_url, t(:create_success, model_name: humanized_model_name))
    else
      failed_response('new', :unprocessable_entity)
    end
  end

  def update
    content_type = content_type_from_controller(self.class)
    @content = content_type.find(params[:id])

    unless @content.updatable_by? current_user
      return redirect_to :back
    end

    Mixpanel::Tracker.new(Rails.application.config.mixpanel_token).track(current_user.id, 'updated content', {
      'content_type': content_type.name
    })

    if params.key? 'image_uploads'
      upload_files params['image_uploads'], content_type.name, @content.id
    end

    if @content.update_attributes(content_params)
      successful_response(@content, t(:update_success, model_name: humanized_model_name))
    else
      failed_response('edit', :unprocessable_entity)
    end
  end

  def upload_files image_uploads_list, content_type, content_id
    image_uploads_list.each do |image_data|
      image_size_kb = File.size(image_data.tempfile.path) / 1000.0

      if current_user.upload_bandwidth_kb < image_size_kb
        flash[:alert] = [
          "At least one of your images failed to upload because you do not have enough upload bandwidth.",
          "<a href='#{subscription_path}' class='btn white black-text center-align'>Get more</a>"
        ].map { |p| "<p>#{p}</p>" }.join
        next
      else
        current_user.update(upload_bandwidth_kb: current_user.upload_bandwidth_kb - image_size_kb)
      end

      related_image = ImageUpload.create(
        user: current_user,
        content_type: content_type,
        content_id: content_id,
        src: image_data,
        privacy: 'public'
      )

      Mixpanel::Tracker.new(Rails.application.config.mixpanel_token).track(current_user.id, 'uploaded image', {
        'content_type': content_type,
        'image_size_kb': image_size_kb,
        'first five images': current_user.image_uploads.count <= 5
      })
    end
  end

  def destroy
    content_type = content_type_from_controller(self.class)
    @content = content_type.find(params[:id])

    unless current_user.can_delete? @content
      return redirect_to :back
    end

    Mixpanel::Tracker.new(Rails.application.config.mixpanel_token).track(current_user.id, 'deleted content', {
      'content_type': content_type.name
    })

    @content.destroy

    successful_response(content_deletion_redirect_url, t(:delete_success, model_name: humanized_model_name))
  end

  private

  def initialize_object
    content_type = content_type_from_controller(self.class)
    @content = content_type.new(content_params).tap do |c|
      c.user_id = current_user.id
    end
  end

  # Override in content classes
  def content_params
    params
  end

  def content_deletion_redirect_url
    send("#{@content.class.name.underscore.pluralize}_path")
  end

  def content_creation_redirect_url
    @content
  end

  def content_symbol
    content_type_from_controller(self.class).to_s.downcase.to_sym
  end

  def successful_response(url, notice)
    respond_to do |format|
      format.html {
        if params.key?(:override) && params[:override].key?(:redirect_path)
          redirect_to params[:override][:redirect_path], notice: notice
        else
          redirect_to url, notice: notice
        end
      }
      format.json { render json: @content || {}, status: :success, notice: notice }
    end
  end

  def failed_response(action, status)
    respond_to do |format|
      format.html { render action: action }
      format.json { render json: @content.errors, status: status }
    end
  end

  def humanized_model_name
    content_type_from_controller(self.class).model_name.human
  end
end
