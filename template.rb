require 'fileutils'
require 'shellwords'

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('jumpstart-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/frankolson/user-jumpstart.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{user-jumpstart/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def add_gems
  gem 'bootstrap', '~> 4.1', '>= 4.1.3'
  gem 'name_of_person', '~> 1.0'
  gem 'devise', '~> 4.5'
  gem 'devise-bootstrapped', github: 'king601/devise-bootstrapped', branch: 'bootstrap4'
  gem 'gravatar_image_tag', github: 'mdeering/gravatar_image_tag'
  gem 'font-awesome-sass', '~> 5.5', '>= 5.5.0.1'
  gem 'jquery-rails', '~> 4.3', '>= 4.3.3'
  gem 'sitemap_generator', '~> 6.0', '>= 6.0.1'
  gem 'webpacker', '~> 3.5', '>= 3.5.3'
  gem 'mini_magick', '~> 4.8'
  gem 'foreman', '~> 0.85'
  gem 'administrate', '~> 0.11'
end

def set_application_name
  environment 'config.application_name = Rails.application.class.parent_name'
  puts 'You can change application name inside: ./config/application.rb'
end

def stop_spring
  run 'spring stop'
end

def add_users
  # Install and Configure Devise
  generate 'devise:install'
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
    env: 'development'
  route "root to: 'home#index'"

  # Bootstrapify devise views
  generate 'devise:views:bootstrapped'

  # Create Devise User
  generate :devise, 'User', 'first_name', 'last_name'

  requirement = Gem::Requirement.new('> 5.2')
  rails_version = Gem::Version.new(Rails::VERSION::STRING)

  if requirement.satisfied_by? rails_version
    gsub_file 'config/initializers/devise.rb',
      /  # config.secret_key = .+/,
      '  config.secret_key = Rails.application.credentials.secret_key_base'
  end
end

def copy_templates
  run 'rm app/assets/stylesheets/application.css'
  directory 'app', force: true
  directory 'config', force: true
  directory 'lib', force: true
end

def add_forman
  copy_file 'Procfile.dev'
end

def add_doc_routes
  route "get '/terms', to: 'home#terms'"
  route "get '/privacy', to: 'home#privacy'"
end

def add_webpack
  rails_command 'webpacker:install'
end

def add_stimulus
  rails_command 'webpacker:install:stimulus'
end

def add_bootstrap
  insert_into_file 'app/assets/javascripts/application.js',
    "\n//= require jquery\n//= require popper\n//= require bootstrap",
    after: "//= require rails-ujs"
end

def add_active_storage
  rails_command 'active_storage:install'
end

def add_sitemap
  rails_command 'sitemap:install'
end


def add_administrate
  generate 'administrate:install'

  gsub_file 'app/dashboards/user_dashboard.rb',
    /email: Field::String/,
    'email: Field::String,\n    password: Field::String.with_options(searchable: false)'

  gsub_file 'app/dashboards/user_dashboard.rb',
    /FORM_ATTRIBUTES = \[/,
    'FORM_ATTRIBUTES = [\n    :password,'

  gsub_file 'app/controllers/admin/application_controller.rb',
    /# TODO Add authentication logic here\./,
    'redirect_to '/', alert: 'Not authorized.' unless user_signed_in? && current_user.admin?'

  environment do <<-RUBY
    # Expose our application's helpers to Administrate
    config.to_prepare do
      Administrate::ApplicationController.helper #{@app_name.camelize}::Application.helpers
    end
  RUBY
  end
end

def initial_webpack_build
  run 'bin/webpack'
end

add_template_repository_to_source_path
add_gems

after_bundle do
  set_application_name
  stop_spring
  add_users

  copy_templates
  add_forman
  add_doc_routes
  add_webpack
  add_stimulus
  add_bootstrap
  add_active_storage

  # Migrate
  rails_command 'db:create'
  rails_command 'db:migrate'

  # Migrations must be done before this
  add_administrate

  add_sitemap

  git :init
  git add: '.'
  git commit: %Q{ -m 'Initial commit' }
end
