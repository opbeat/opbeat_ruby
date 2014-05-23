require 'capistrano'

module Opbeat
  module Capistrano
    def self.load_into(configuration)

      configuration.load do
        after "deploy", "opbeat:notify"
        namespace :opbeat do
          desc "Notifies Opbeat of new deployments"
          task :notify, :except => { :no_release => true } do

            scm = fetch(:scm)
            if scm != "git"
              puts "Skipping Opbeat deployment notification because scm is not git."
              next
            end
          
            branches = capture("cd #{current_release}; /usr/bin/env git branch --contains #{current_revision}").split
            if branches.length == 1
              branch = branch[0].sub("* ")
            else
              branch = nil
            end  

            notify_command = "cd #{current_release}; REV=#{current_revision} "
            notify_command << "BRANCH=#{branch} " if branch

            executable = fetch(:rake, 'bundle exec rake ')
            notify_command << "#{executable} opbeat:deployment"
            capture notify_command, :once => true
          
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Opbeat::Capistrano.load_into(Capistrano::Configuration.instance)
end
