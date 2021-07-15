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

require_dependency 'mail_handler'

module MailHandlerPatch
  def self.included(base) # :nodoc:
    base.send(:include, InstanceMethods)

    base.class_eval do
      alias_method :receive_issue_without_hook, :receive_issue
      alias_method :receive_issue, :receive_issue_with_hook

      alias_method :receive_issue_reply_without_hook, :receive_issue_reply
      alias_method :receive_issue_reply, :receive_issue_reply_with_hook
    end
  end

  module InstanceMethods
    def receive_issue_with_hook
      issue = receive_issue_without_hook
      unless issue.nil?
        Redmine::Hook.call_hook(:model_mail_handler_receive_issue_after_save, {:issue => issue})
      end
      issue
    end

    def receive_issue_reply_with_hook(issue_id, from_journal=nil)
      journal = receive_issue_reply_without_hook(issue_id, from_journal)
      unless journal.nil?
        Redmine::Hook.call_hook(:model_mail_handler_receive_issue_reply_after_save, {:issue => journal.issue, :journal => journal})
      end
      journal
    end
  end
end

MailHandler.send(:include, MailHandlerPatch)
