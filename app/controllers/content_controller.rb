class ContentController < ApplicationController
  include HasOwnership

  before_action :create_anonymous_account_if_not_logged_in, only: [:edit, :create, :update]
  before_action :set_content_type_as_string

  def index
    @content = content_type_from_controller(self.class)
      .where(user_id: session[:user])
      .order(:name)
      .presence || []

    @page_title = "Your #{@content_type_as_string.pluralize}".capitalize

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @content }
    end
  end

  def show
    @content = content_type_from_controller(self.class)
      .find(params[:id])

    @page_title = "#{@content_type_as_string} #{@content.name}"

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @content }
    end
  end

  def new
    @content = content_type_from_controller(self.class)
    	.new

    @page_title = "New #{@content_type_as_string}"

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @content }
    end
  end

  def edit
    @content = content_type_from_controller(self.class)
    	.find(params[:id])

    @page_title = "Editing #{@content.name}"
  end

  def create
    initialize_object

    if @content.save
      successful_response(@content, t(:create_success, model_name: humanized_model_name))
    else
      failed_response('new', :unprocessable_entity)
    end
  end

  def update
    content_type = content_type_from_controller(self.class)
    @content = content_type.find(params[:id])

    if @content.update_attributes(content_params)
      successful_response(@content, t(:update_success, model_name: humanized_model_name))
    else
      failed_response('edit', :unprocessable_entity)
    end
  end

  def destroy
    content_type = content_type_from_controller(self.class)
    @content = content_type.find(params[:id])
    @content.destroy

    url = send("#{@content.class.to_s.downcase}_list_path")
    successful_response(url, t(:delete_success, model_name: humanized_model_name))
  end

  private

  def initialize_object
    content_type = content_type_from_controller(self.class)
    @content = content_type
      .new(content_params)
      .tap do |c|
        c.user_id = session[:user]
        c.universe = universe_from_params if c.respond_to? :universe #todo this doesn't actually work?
      end
  end

  # Override in content classes
  def content_params
    params
  end

  def universe_from_params
    return unless params[content_symbol].include? :universe
    Universe.where(user_id: session[:user], name: params[content_symbol][:universe].strip).first
  end

  def content_symbol
    content_type_from_controller(self.class).to_s.downcase.to_sym
  end

  def set_content_type_as_string
    @content_type_as_string = content_type_from_controller_as_string(self.class)
  end

  def successful_response(url, notice)
    respond_to do |format|
      format.html { redirect_to url, notice: notice }
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
