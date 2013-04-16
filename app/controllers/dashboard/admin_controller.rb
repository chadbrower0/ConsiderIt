require 'date'

class Dashboard::AdminController < Dashboard::DashboardController
  respond_to :json
  
  def application
    if !current_user.is_admin?
      redirect_to root_path, :notice => "You need to be an admin to access that page."
      return
    end

    @sidebar_context = :admin
    @selected_navigation = :app_settings
  end

  def proposals
    if !(current_user.is_admin? || current_user.has_role?(:manager))
      redirect_to root_path, :notice => "You need to be an admin to do that."
      return
    end

    @sidebar_context = :admin
    @selected_navigation = :manage_proposals
  end

  def roles

    if !(current_user.is_admin? || current_user.has_role?(:manager))
      redirect_to root_path, :notice => "You need to be an admin to access that page."
      return
    end

    render :json => { 
      :users_by_roles_mask => current_tenant.users.order('roles_mask DESC').select([:id, :name, :email, :roles_mask]), 
      :admin_template => params["admin_template_needed"] == 'true' ? self.admin_template() : nil}

  end

  def update_role

    if !(current_user.is_admin? || current_user.has_role?(:manager))
      redirect_to root_path, :notice => "You need to be an admin to do that."
      return
    end

    user = User.find(params[:user_id])

    if params[:user][:role] == 'admin'
      user.roles = :admin
    elsif params[:user][:role] == 'user'
      user.roles = nil
    else
      [:moderator, :manager, :analyst].each do |role|
        user.roles.delete(role)
        if params[:user][role] == '1'
          user.roles << role
        end
      end
    end

    user.save

    resp = { :role_list => user.role_list } 
    render :json => resp.to_json
  end

  def analytics
    if !(current_user.is_admin? || current_user.has_role?(:analyst))
      redirect_to root_path, :notice => "You need to be an admin to access that page."
      return
    end

    @series = []

    has_permission = current_user && (current_user.is_admin? || current_user.has_role?(:analyst) )
    classes = has_permission ? [Session, User, Position, Inclusion, Point, Commentable::Comment] : []

    classes.each_with_index do |data, idx|
      dates = {}
      name = data.name.split('::').last

      if [Position, Point].include?(data)
        qry = data.published
      else
        qry = data
      end

      if [Inclusion].include? data
        qry = qry
                .joins(:position)
                .where('positions.published = 1')
                .where('inclusions.created_at is not null')
                .select('count(*) as cnt, inclusions.created_at')
                .group('YEAR(inclusions.created_at), MONTH(inclusions.created_at), DAY(inclusions.created_at)')
      else
        qry = qry.select('count(*) as cnt, created_at')
                .group('YEAR(created_at), MONTH(created_at), DAY(created_at)')
                .where('created_at is not null')
      end

      qry = qry.order('created_at')

      time = []
      qry.each do |obj|
         time.push([obj.created_at.to_date.strftime('%s').to_i * 1000, obj.cnt ])
      end

      cumulative = []
      prev = 0
      time.each_with_index do |row, idx|
        cumulative.push([row[0], row[1] + prev])
        prev += row[1]
      end

      @series.push( {
        :title => name,
        :main => { :title => name, :data => time}, 
        :cumulative => { :title => 'Cumulative ' + name, :data => cumulative}
      })
    end

    render :json => { 
      :analytics_data => @series,
      :admin_template => params["admin_template_needed"] == 'true' ? self.admin_template() : nil}

  end


end