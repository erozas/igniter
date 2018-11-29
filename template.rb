require "fileutils"
require "shellwords"

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("igniter"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/erozas/igniter.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{igniter/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def add_gems
  gem 'administrate', '~> 0.11.0'
  gem 'aws-sdk-s3', '~> 1.24', '>= 1.24.1'
  gem 'devise', '~> 4.5'
  gem 'devise_masquerade', '~> 0.6.5'
  gem 'fastimage', '~> 2.1', '>= 2.1.4'
  gem 'foreman', '~> 0.85.0'
  gem 'friendly_id', '~> 5.2', '>= 5.2.4'  
  gem 'image_processing', '~> 1.7', '>= 1.7.1'
  gem 'omniauth-facebook'
  gem 'omniauth-google-oauth2'
  gem 'shrine', '~> 2.13'
  gem 'sidekiq', '~> 5.2', '>= 5.2.3'
  gem 'sitemap_generator', '~> 6.0', '>= 6.0.1'
  gem 'validates_email_format_of', '~> 1.6', '>= 1.6.3'
  gem 'webpacker', '~> 3.5', '>= 3.5.5'
  gem 'whenever', require: false

  gem_group :development, :test do
    gem 'better_errors'
    gem 'capybara'
    gem 'factory_bot_rails', '~> 4.11', '>= 4.11.1'
    gem 'ffaker', '~> 2.10'
    gem 'poltergeist', '~> 1.18', '>= 1.18.1'
    gem 'rails-controller-testing', '~> 1.0', '>= 1.0.2'
    gem 'rspec-rails', '~> 3.8', '>= 3.8.1'
  end
  
  gem_group :test do
    gem 'database_cleaner', '~> 1.7'
    gem 'guard-rspec', '~> 4.7', '>= 4.7.3'
    gem 'shoulda', '~> 3.6'
    gem 'shrine-memory', '~> 0.3.0'
  end
end

def set_application_name
  application_name = ask("What is the name of your application? Default: Ignite")
  application_name = application_name.present? ? application_name : "Ignite"
  environment "config.application_name = '#{application_name}'"
  puts "Your application name is #{application_name}. You can change this later on: ./config/application.rb"
end

def stop_spring
  run "spring stop"
end

def set_root_route
  route "root to: 'pages#home'"
end

def set_available_locale
  environment "config.i18n.default_locale = :es"
end

def install_rspec
  rails_command "generate rspec:install"
end

def add_users
  generate "devise:install"

  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  # Create Devise User
  generate :devise, "User",
           "username",
           "first_name",
           "last_name",
           "admin:boolean"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  requirement = Gem::Requirement.new("> 5.2")
  rails_version = Gem::Version.new(Rails::VERSION::STRING)

  if requirement.satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb",
      /  # config.secret_key = .+/,
      "  config.secret_key = Rails.application.credentials.secret_key_base"
  end

  # Add Devise masqueradable to users
  inject_into_file("app/models/user.rb", "omniauthable, :masqueradable, :", after: "devise :")
end

def add_multiple_authentication
    insert_into_file "config/routes.rb",
    ', controllers: { omniauth_callbacks: "users/omniauth_callbacks" }',
    after: "  devise_for :users"

    generate "model Service user:references provider uid access_token access_token_secret refresh_token expires_at:datetime auth:text"

    template = """
    config.omniauth :facebook, nil, nil, scope: 'email,user_posts'

    config.omniauth :google_oauth2, nil, nil
    """.strip

    insert_into_file "config/initializers/devise.rb", "  " + template + "\n\n",
          before: "  # ==> Warden configuration"
    puts "Don't forget to add your omniauth client app credentials in config/initializers/devise.rb"
end

def add_webpack
  rails_command "webpacker:install"
end

def add_css_framework
  add_bootstrap
end

def add_friendly_id
  generate "friendly_id"

  insert_into_file(
    Dir["db/migrate/**/*friendly_id_slugs.rb"].first,
    "[5.2]",
    after: "ActiveRecord::Migration"
  )
end

def rename_app_css_to_app_scss
  run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss"
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  insert_into_file "config/routes.rb",
    "  authenticate :user, lambda { |u| u.admin? } do\n    mount Sidekiq::Web => '/sidekiq'\n  end\n\n",
    after: "Rails.application.routes.draw do\n"
end

def add_foreman
  copy_file "Procfile"
end

def copy_templates
  directory "app", force: true
  directory "config", force: true
  directory "lib", force: true
  directory "spec", force: true
end

def add_administrate
  generate "administrate:install"

  gsub_file "app/dashboards/user_dashboard.rb",
    /email: Field::String/,
    "email: Field::String,\n    password: Field::String.with_options(searchable: false)"

  gsub_file "app/dashboards/user_dashboard.rb",
    /FORM_ATTRIBUTES = \[/,
    "FORM_ATTRIBUTES = [\n    :password,"

  gsub_file "app/controllers/admin/application_controller.rb",
    /# TODO Add authentication logic here\./,
    "redirect_to '/', alert: 'Not authorized.' unless user_signed_in? && current_user.admin?"
end

def add_app_helpers_to_administrate
  environment do <<-RUBY
    # Expose our application's helpers to Administrate
    config.to_prepare do
      Administrate::ApplicationController.helper #{@app_name.camelize}::Application.helpers
    end
  RUBY
  end
end

def add_static_pages
  route "get '/terminos-y-condiciones', to: 'pages#terms'"
  route "get '/politica-de-privacidad', to: 'pages#privacy'"
  route "get '/sobre-nosotros', to: 'pages#about_us'"
  route "get '/preguntas-frecuentes', to: 'pages#faq'"
end

def add_whenever
  run "wheneverize ."
end

def add_sitemap
  rails_command "sitemap:install"
end

# Main setup
add_template_repository_to_source_path

add_gems

after_bundle do
  set_application_name
  stop_spring
  set_root_route
  set_available_locale
  install_rspec

  add_users

  add_webpack
  add_multiple_authentication
  add_css_framework
  add_friendly_id
  rename_app_css_to_app_scss

  add_sidekiq
  add_foreman

  copy_templates

  # Migrate
  rails_command "db:create"
  rails_command "db:migrate"

  add_administrate
  add_app_helpers_to_administrate
  add_static_pages
  add_whenever
  add_sitemap

  git :init
  git add: "."
  git commit: %Q{ -m "Initial commit" }
end


def add_bootstrap
  run "yarn --ignore-engines add bootstrap popper.js jquery"
  run "mkdir app/javascript/stylesheets && touch app/javascript/stylesheets/application.scss"
  append_to_file "app/javascript/packs/application.js", 'import "../stylesheets/application";'
  append_to_file "app/javascript/packs/application.js", 'import "bootstrap";'
  append_to_file "app/javascript/stylesheets/application.scss", "\n @import '~bootstrap/dist/css/bootstrap';"
  directory "config", force: true
end