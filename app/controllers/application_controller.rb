class ApplicationController < ActionController::Base
  protect_from_forgery

  before_action :cache_most_used_page_information
  before_action :cache_forums_unread_counts

  # todo name all these methods
  before_action do
    if params[:universe].present? && user_signed_in?
      if params[:universe] == 'all'
        session.delete(:universe_id)
      elsif params[:universe].is_a?(String) && params[:universe].to_i.to_s == params[:universe]
        found_universe = Universe.find_by(id: params[:universe])
        found_universe = nil unless current_user.universes.include?(found_universe) || current_user.contributable_universes.include?(found_universe)
        session[:universe_id] = found_universe.id if found_universe
      end
    end
  end

  before_action do
    if current_user && session[:universe_id]
      @universe_scope = Universe.find_by(id: session[:universe_id])
      @universe_scope = nil unless current_user.universes.include?(@universe_scope) || current_user.contributable_universes.include?(@universe_scope)
    else
      @universe_scope = nil
    end
  end

  before_action do
    @page_title ||= ''
    @page_keywords ||= %w[writing author nanowrimo novel character fiction fantasy universe creative dnd roleplay larp game design]
    @page_description ||= 'Notebook.ai is a set of tools for writers, game designers, and roleplayers to create magnificent universes — and everything within them.'
  end

  def content_type_from_controller(content_controller_name)
    content_controller_name.to_s.chomp('Controller').singularize.constantize
  end

  private

  # Cache some super-common stuff we need for every page. For example, content lists for the side nav.
  def cache_most_used_page_information
    return unless user_signed_in?

    @activated_content_types = (
      Rails.application.config.content_types[:all].map(&:name) & # Use config to dictate order, but AND to only include what a user has turned on
      current_user.user_content_type_activators.pluck(:content_type)
    )

    # We always want to cache Universes, even if they aren't explicitly turned on.
    @current_user_content = current_user.content(content_types: @activated_content_types + ['Universe'])
    @current_user_content['Document'] = current_user.documents
  end

  def cache_forums_unread_counts
    @unread_threads = if user_signed_in?
      Thredded::Topic.unread_followed_by(current_user).count
    else
      0
    end

    @unread_private_messages = if user_signed_in?
      Thredded::PrivateTopic
        .for_user(current_user)
        .unread(current_user)
        .count
    else
      0
    end
  end
end
