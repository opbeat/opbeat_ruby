namespace :opbeat do
  desc "Notifies Opbeat of new deployments"
  task :notify do
    on roles(:app) do

      scm = fetch(:scm)
      if scm.to_s != "git"
        info "Skipping Opbeat deployment because scm is not git."
        next
      end

      rev = fetch(:current_revision)
      branch = fetch(:branch, 'master')

      within release_path do
        with rails_env: fetch(:rails_env), rev: rev, branch: branch do
          capture :rake, 'opbeat:deployment'
        end
      end
    end

      # within repo_path do
      #   rev = fetch(:current_revision)

      #   branches = capture("cd #{repo_path}; /usr/bin/env git branch --contains #{rev}").split
      #   if branches.length == 1
      #     branch = branches[0].sub("* ", "")
      #   else
      #     branch = nil
      #   end

      #   notify_command = "REV=#{rev} "
      #   notify_command << "BRANCH=#{branch} " if branch

      #   rails_env = fetch(:rails_env, "production")
      #   notify_command << "RAILS_ENV=#{rails_env} "

      #   executable = fetch(:rake, 'bundle exec rake ')
      #   notify_command << "#{executable} opbeat:deployment"
      #   capture ("cd #{release_path};" + notify_command), :once => true
      # end
    # end
  end
end

namespace :deploy do
  after :publishing, "opbeat:notify"
end
