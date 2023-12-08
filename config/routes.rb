# nxs-chat-redmine - plugin for Redmine
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

get 'localizations/issue_priorities', :to => 'user_chats#show_issue_priorities'

get 'users/:id/last_issue', :to => 'user_chats#show_last_issue'
get 'users_languages', :to => 'user_chats#index_languages'

get 'plugins/nxs_chat/info', :to => 'user_chats#show_plugin_info'
