# nxs-chat-redmine - plugin for Redmine
# Copyright (C) 2006-2014  Jean-Philippe Lang
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

require 'net/http'
require 'uri'
require 'open-uri'
require 'json'

module ChatHelper
  def self.included(base) # :nodoc:
    base.send(:include, InstanceModules)
  end

  module InstanceModules
    module Chat
      include Redmine::I18n

      def self.localize(method)
        name = {
          'default': self.localize_with_locale(Setting.default_language, method)
        }

        locales = Setting.plugin_nxs_chat['notifications_locales']
        locales.each do |locale|
          name[locale.to_s] = self.localize_with_locale(locale, method)
        end

        return name
      end

      # Based on process() method from redmine/app/models/mailer.rb
      def self.localize_with_locale(locale, method)
        initial_user = User.current
        initial_language = ::I18n.locale
        begin
          User.current = User.anonymous
          set_language_if_valid(locale)

          return method.call()
        ensure
          User.current = initial_user
          ::I18n.locale = initial_language
        end
      end

      # Return hash with data from issue and journals (optional) objects
      #
      # Based on template from redmine/app/views/issues/show.api.rsb
      def self.issue_as_json(issue: nil, journals: nil)
        json = {}

        json[:id] = issue.id

        unless issue.project.nil?
          json[:project] = {:id => issue.project_id, :name => issue.project.name}

          unless issue.project.members.nil?
            json[:project][:members] = []
            issue.project.members.each do |member|
              membership = {
                :id => member.user.id,
                :name => member.user.name,
                :access => {
                  :view_current_issue => issue.visible?(member.user),
                  :view_private_notes => member.user.allowed_to?(:view_private_notes, issue.project)
                },
                :roles => []
              }
              member.roles.each do |role|
                membership[:roles] += [{
                  :id => role.id,
                  :name => role.name,
                  :permissions => {
                    :issues_visibility => role.issues_visibility,
                    :view_private_notes => role.has_permission?(:view_private_notes)
                  }
                }]
              end
              json[:project][:members] += [membership]
            end
          end
        end

        json[:tracker] = {:id => issue.tracker_id, :name => localize(issue.tracker.method(:name))} unless issue.tracker.nil?
        json[:status] = {:id => issue.status_id, :name => localize(issue.status.method(:name))} unless issue.status.nil?
        json[:priority] = {:id => issue.priority_id, :name => localize(issue.priority.method(:name))} unless issue.priority.nil?
        json[:author] = {:id => issue.author_id, :name => issue.author.name} unless issue.author.nil?
        json[:assigned_to] = {:id => issue.assigned_to_id, :name => issue.assigned_to.name} unless issue.assigned_to.nil?
        json[:category] = {:id => issue.category_id, :name => localize(issue.category.method(:name))} unless issue.category.nil?
        json[:fixed_version] = {:id => issue.fixed_version_id, :name => issue.fixed_version.name} unless issue.fixed_version.nil?
        json[:parent] = {:id => issue.parent_id} unless issue.parent.nil?

        json[:subject] = issue.subject
        json[:description] = issue.description
        json[:start_date] = issue.start_date
        json[:due_date] = issue.due_date
        json[:done_ratio] = issue.done_ratio
        json[:is_private] = issue.is_private
        json[:estimated_hours] = issue.estimated_hours
        json[:spent_hours] = issue.spent_hours

        begin
          unless issue.mentioned_users.nil?
            json[:mentioned_users] = []
            issue.mentioned_users.each do |mentioned_user|
              json[:mentioned_users] += [{:id => mentioned_user.id, :name => mentioned_user.name}]
            end
          end
        rescue NoMethodError
          # `mentioned_users` method was added in Redmine 5.0. So we should ignore exception
          # until support for Redmine 4.2 will be dropped.
        end

        # Custom values
        unless issue.custom_field_values.nil?
          json[:custom_fields] = []
          issue.custom_field_values.each do |custom_value|
            attrs = {:id => custom_value.custom_field_id, :name => localize(custom_value.custom_field.method(:name))}
            attrs.merge!(:multiple => true) if custom_value.custom_field.multiple?

            if custom_value.value.is_a?(Array)
              attrs[:value] = []
              custom_value.value.each do |value|
                attrs[:value] += [value] unless value.blank?
              end
            else
              attrs[:value] = custom_value.value
            end
          json[:custom_fields] += [attrs]
          end
        end

        json[:created_on] = issue.created_on
        json[:updated_on] = issue.updated_on
        json[:closed_on] = issue.closed_on

        # Attachments
        unless issue.attachments.nil?
          json[:attachments] = []
          issue.attachments.each do |attachment|
            a = {}
            a["id"] = attachment.id
            a["filename"] = attachment.filename
            a["filesize"] = attachment.filesize
            a["content_type"] = attachment.content_type
            a["description"] = attachment.description
            #a["content_url"] = url_for(:controller => 'attachments', :action => 'download', :id => attachment, :filename => attachment.filename, :only_path => false) # TODO
            a["author"] = {:id => attachment.author.id, :name => attachment.author.name} unless attachment.author.nil?
            a["created_on"] = attachment.created_on

            json[:attachments] += [a]
          end
        end

        # TODO: relations

        # TODO: changesets

        # Journals
        unless journals.nil?
          json[:journals] = []
          journals.each do |journal|
            j = {}
            j[:id] = journal.id

            # Not all journals have an index. For example time spend report without note will not be
            # shown as separate comment on an issue history page.
            journal_with_index = issue.visible_journals_with_index.find{|j| j.id == journal.id}
            j[:indice] = journal_with_index.indice unless journal_with_index.nil?

            j[:user] = {:id => journal.user_id, :name => journal.user.name} unless journal.user.nil?
            j[:notes] = journal.notes
            j[:private_notes] = journal.private_notes
            j[:created_on] = journal.created_on
            j[:details] = []
            journal.visible_details.each do |detail|
              j[:details] += [{
                :property => detail.property,
                :name => detail.prop_key,
                :old_value => detail.old_value,
                :new_value => detail.value
              }]
            end

            begin
              unless journal.mentioned_users.nil?
                j[:mentioned_users] = []
                journal.mentioned_users.each do |mentioned_user|
                  j[:mentioned_users] += [{:id => mentioned_user.id, :name => mentioned_user.name}]
                end
              end
            rescue NoMethodError
              # `mentioned_users` method was added in Redmine 5.0. So we should ignore exception
              # until support for Redmine 4.2 will be dropped.
            end

            json[:journals] += [j]
          end
        end

        # Watchers
        unless issue.watcher_users.nil?
          json[:watchers] = []
          issue.watcher_users.each do |user|
            json[:watchers] += [{ :id => user.id, :name => user.name }]
          end
        end

        json
      end

      # Sent event info to external web server (webhook)
      #
      # Arguments should support converting to JSON object
      def self.send_event(action: nil, data: nil)
        case action
        when :issue_create
          sub_path = "v2/redmine/created"
        when :issue_edit
          sub_path = "v2/redmine/updated"
        else
          logger.error "Unexpected event type: #{action}" if logger
          return
        end

        begin
          uri = URI::join(Setting.plugin_nxs_chat['notifications_endpoint'], sub_path)
        rescue => e
          # Plugin is not configured properly
          logger.error "Parsing URI for notifications failed:\n"\
                       "  Exception: #{e.message}" if logger
          return
        end

        unless uri.kind_of?(URI::HTTP) or uri.kind_of?(URI::HTTPS)
          logger.error "Parsing URI for notifications failed" if logger
          return
        end

        # Prepare the data
        header = {
          'Content-Type' => 'text/json'
        }
        json_data = JSON.generate({ :data => data })

        # Create the HTTP objects
        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Setting.plugin_nxs_chat['notifications_endpoint_ssl_verify_none']
        end
        request = Net::HTTP::Post.new(uri.request_uri, header)
        request.body = json_data

        token = Setting.plugin_nxs_chat['notifications_token']
        if token
          request['Authorization'] = "Bearer #{token}"
        end

        # Send the request
        begin
          response = http.request(request)
        rescue => e
          logger.error "Sending notification failed:\n"\
                       "  URI: #{uri}\n"\
                       "  Exception: #{e.message}" if logger
          return
        end

        unless response.code.to_i == 200
          logger.error "Sending notification failed:\n"\
                       "  URI: #{uri}\n"\
                       "  Response code: #{response.code}" if logger
          return
        else
          logger.info "Notification has been sent successfully:\n"\
                      "  URI: #{uri}\n"\
                      "  Response code: #{response.code}" if logger
        end
      end

      def self.logger
        Rails.logger
      end
    end
  end
end

Redmine::Helpers.send(:include, ChatHelper)
