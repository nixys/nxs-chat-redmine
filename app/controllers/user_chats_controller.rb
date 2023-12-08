# nxs-chat-redmine - plugin for Redmine
# Copyright (C) 2006-2016  Jean-Philippe Lang
# Copyright (C) 2017  Nixys Ltd.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

class UserChatsController < ApplicationController
  layout 'admin'

  before_action :require_admin, :except => :show_last_issue
  before_action :find_user, :only => :show_last_issue
  accept_api_auth :show_issue_priorities, :show_last_issue, :index_languages, :show_plugin_info

  helper :sort
  include SortHelper
  helper :custom_fields
  include CustomFieldsHelper

  API_VERSION = "v2"

  def show_issue_priorities
    @enumerations = Enumeration.get_subclass(:issue_priorities).shared.sorted.to_a

    respond_to do |format|
      format.api
    end
  end

  def show_last_issue
    unless User.current.admin?
      (render_404; return) unless @user.active?
      (render_403; return) unless @user == User.current
    end

    issue = Issue.where(:author_id => @user).order(:created_on).last
    journal = Journal.where(:user_id => @user).order(:created_on).last

    if issue.nil? and journal.nil?
      @last_issue = nil
    elsif issue.nil?
      @last_issue = journal.issue
    elsif journal.nil?
      @last_issue = issue
    else
      @last_issue = (issue.created_on >= journal.created_on) ? issue : journal.issue
    end

    respond_to do |format|
      format.api
    end
  end

  # Based on UsersController#index from redmine/app/controllers/users_controller.rb
  def index_languages
    sort_init 'login', 'asc'
    sort_update %w(login firstname lastname mail admin created_on last_login_on)

    @offset, @limit = api_offset_and_limit

    @status = params[:status] || 1

    scope = User.logged.status(@status)
    scope = scope.like(params[:name]) if params[:name].present?
    scope = scope.in_group(params[:group_id]) if params[:group_id].present?

    @user_count = scope.count
    @user_pages = Paginator.new @user_count, @limit, params['page']
    @offset ||= @user_pages.offset
    @users =  scope.order(sort_clause).limit(@limit).offset(@offset).all

    respond_to do |format|
      format.api
    end
  end

  def show_plugin_info
    @api_version = API_VERSION

    respond_to do |format|
      format.api
    end
  end

  private

  def find_user
    if params[:id] == 'current'
      require_login || return
      @user = User.current
    else
      @user = User.find(params[:id])
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
