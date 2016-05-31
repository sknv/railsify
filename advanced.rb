# An advanced Rails application template with frontend and admin sections
#
# Usage example: rails new APP_NAME -m ~/advanced.rb

require_relative 'lib/railsify'

# Override resolving directory for Thor actions to use template's folder
def source_paths
  Railsify::PathResolver.resolve_source_paths(__FILE__)
end

# Add gems and comment unnecessary ones
gem 'autoprefixer-rails', '~> 6.3'
gem 'devise', '~> 4.1'
gem 'devise-i18n', '~> 1.0'
gem 'rails-i18n', '~> 5.0.0.beta4'
comment_lines 'Gemfile', 'coffee-rails'

# Use jQuery 2
gsub_file 'app/assets/javascripts/application.js', "jquery\n", "jquery2\n"

# Set time zone and locale
inject_into_class 'config/application.rb', 'Application', <<-CODE
    # Set russian time zone and locale
    config.time_zone = 'Europe/Moscow'
    config.i18n.default_locale = :ru
    # Let the rails-i18n gem load only russian locale
    config.i18n.available_locales = :ru

CODE
copy_file 'config/locales/ru.yml'

# Add helper to print full page title
insert_into_file 'app/helpers/application_helper.rb',
                 after: "ApplicationHelper\n" do
  <<-'CODE'
  # Returns the full title on a per-page basis
  def full_title(page_title)
    base_title = 'RailsApp'
    if page_title.empty?
      base_title
    else
      "#{base_title} | #{page_title}"
    end
  end
  CODE
end

# Set some layout defaults
gsub_file 'app/views/layouts/application.html.erb', '<html>',
          '<html lang="<%= I18n.locale %>">'
gsub_file 'app/views/layouts/application.html.erb', %r{<title>.*</title>},
          '<title><%= full_title yield(:title) %></title>'
copy_file 'app/views/shared/_flashes.html.erb'
insert_into_file 'app/views/layouts/application.html.erb',
                 "    <%= render 'shared/flashes' %>\n", after: "<body>\n"

# Devise required config
insert_into_file 'config/environments/development.rb', before: "\nend" do
  <<-CODE
  \n
  # Configure mailer for Devise
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  CODE
end

# Install Devise
generate 'devise:install'
generate 'devise', 'User'
inject_into_class 'app/models/user.rb', 'User', 'enum role: [:user, :admin]'
generate :migration, 'AddRoleToUser', 'role:integer'
migration_file = Railsify::Actions.get_matching_path(
  'db/migrate/*_add_role_to_user.rb')
insert_into_file migration_file, ', default: 0',
                 after: ':role, :integer'

# Add admin controller and corresponding view
generate :controller, 'Admin/Pages', 'index'
# Protect admin area from unauthorized access
copy_file 'app/controllers/concerns/administrable.rb'
copy_file 'app/controllers/admin/application_controller.rb'
gsub_file 'app/controllers/admin/pages_controller.rb', 'ApplicationController',
          'Admin::ApplicationController'

# Add default controller and corresponding view
generate :controller, 'Pages', 'index'
route "root: 'pages#index'"
prepend_to_file 'app/views/pages/index.html.erb',
                "<% provide :title, t('.welcome') %>\n"