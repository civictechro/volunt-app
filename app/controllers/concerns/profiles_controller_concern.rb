module ProfilesControllerConcern
  extend ActiveSupport::Concern
  include SearchConcern
  
  included do
    before_action :set_profile, only: [:show, :edit, :update, :destroy]
  end

  def new
    @profile = Profile.new
    profile_set_flag(@profile)
  end
  
  def edit
  end

  def create
    @profile = Profile.new(profile_params)
    profile_set_flag(@profile)
    if @profile.save
      redirect_to profile_path(@profile), notice: 'Profile was succesfully created'
    else
      render :new
    end
  end

  def update
    if @profile.update(profile_params)
      redirect_to profile_path(@profile), notice: 'Profile was succesfully updated'
    else
      render :edit
    end
  end

  def destroy
    @profile.destroy
    redirect_to profiles_path, notice: 'Profile was succesfully deleted'
  end

  def index
    @profile_search_presenter = ProfileSearchPresenter.new
    @profiles = profiles_scope.order(:full_name).paginate(page: params[:page])
  end

  def show
  end

  def search
    @profile_search_presenter = ProfileSearchPresenter.new search_params
    if @profile_search_presenter.blank?
      redirect_to profiles_path
      return
    end
    
    profiles = profiles_scope
    profiles = chain_where_like(profiles, 'full_name', @profile_search_presenter.full_name);
    profiles = chain_where_like(profiles, 'email', @profile_search_presenter.email);
    profiles = chain_where_like(profiles, 'location', @profile_search_presenter.location);

    unless @profile_search_presenter.attrs.blank?
      # attrs is a mixed value: tags, skills and title
      # two of them are arrays, one is string. Enjoy
      
      # transform attrs into tags (split, upercase, no spaces)
      tags = @profile_search_presenter.attrs.split(/\,|;/).map {|x| x.strip.upcase}

      # positive vs. negative
      pos_tags, neg_tags = split_tags_pos_neg(tags)

      tags_sql, tags_opts = define_where_fragment_array_pos_neg("tags", pos_tags, neg_tags)
      skills_sql, skills_opts = define_where_fragment_array_pos_neg("skills", pos_tags, neg_tags)     
      # for title we not consider negative tags as it would qualify everything
      title_sql, title_opts = define_where_fragment_like_pos_neg('title', pos_tags, [])

      sql = "(#{tags_sql}) OR (#{skills_sql})"
      opts = tags_opts.concat(skills_opts)
      unless title_opts.blank?
        sql += " OR (#{title_sql})"
        opts = opts.concat(title_opts)
      end

      puts sql
      puts opts.inspect

      profiles = profiles.where(sql, *opts)
    end

    @profiles = profiles.order(:full_name)
  end


  private

  def search_params
    params.fetch(:profile_search_presenter, {}).permit(
      :full_name, :email, :location, :attrs)
  end

  def set_profile
    @profile = profiles_scope.find params[:id]
  end

  def profile_params
    params.fetch(:profile, {}).permit(
      :full_name,
      :nick_name,
      :photo,
      :tags_string,
      :skills_string,
      :location,
      :title,
      :workplace,
      :email,
      :description,
      :urls_string)
  end

  module ClassMethods

    def profile_controller(controller)
      controller_path = "#{controller}_path"
      # sym pluralize wannabe
      controllers_path = "#{controller}s_path"
      controller_scope = "#{controller}s"
      profile_flag = "Profile::PROFILE_FLAG_#{controller.upcase}".constantize
      helper_method :profile_path, :profiles_path
      define_method 'profile_path' do |profile|
        send(controller_path, profile)
      end
      define_method 'profiles_path' do
        send(controllers_path)
      end

      define_method 'profiles_scope' do
        Profile.send(controller_scope)
      end

      define_method 'profile_set_flag' do |profile|
        profile.flags = profile_flag
      end

    end
    
  end

end
