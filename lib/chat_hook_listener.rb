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

require 'chat_helper'

class ChatHookListener < Redmine::Hook::Listener
  def controller_issues_new_after_save(context = {})
    data = {
      :issue => Redmine::Helpers::Chat::issue_as_json(:issue => context[:issue])
    }

    Redmine::Helpers::Chat::send_event(:action => :issue_create, :data => data)
  end

  def model_mail_handler_receive_issue_after_save(context = {})
    data = {
      :issue => Redmine::Helpers::Chat::issue_as_json(:issue => context[:issue])
    }

    Redmine::Helpers::Chat::send_event(:action => :issue_create, :data => data)
  end

  def controller_issues_edit_after_save(context = {})
    data = {
      :issue => Redmine::Helpers::Chat::issue_as_json(:issue => context[:issue], :journals => [context[:journal]])
    }

    Redmine::Helpers::Chat::send_event(:action => :issue_edit, :data => data)
  end

  def model_mail_handler_receive_issue_reply_after_save(context = {})
    data = {
      :issue => Redmine::Helpers::Chat::issue_as_json(:issue => context[:issue], :journals => [context[:journal]])
    }

    Redmine::Helpers::Chat::send_event(:action => :issue_edit, :data => data)
  end

end
