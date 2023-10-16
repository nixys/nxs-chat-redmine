require 'redmine'

$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/lib"

require_dependency 'mail_handler_patch'
require_dependency 'chat_hook_listener'

Redmine::Plugin.register :nxs_chat do
  name 'nxs-chat'
  author 'Nixys Ltd.'
  description 'Plugin for integration with nxs-chat-srv (Telegram bot by Nixys)'
  version '4.0.0'
  url 'https://github.com/nixys/nxs-chat-redmine'
  author_url 'https://nixys.ru/'

  settings :default => {'empty' => true}, :partial => 'settings/nxs_chat'
end
