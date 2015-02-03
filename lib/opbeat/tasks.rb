# Capistrano tasks for notifying Opbeat of deploys
namespace :opbeat do
  desc "Notify Opbeat of a new deploy."
  task :deployment do
    if defined?(::Rails.root)
      initializer_file = ::Rails.root.join('config', 'initializers','opbeat.rb')

      if initializer_file.exist?
        load initializer_file
      else
        Rake::Task[:environment].invoke
      end
    end
    rev = ENV['REV']

    unless rev
      puts "No revision given. Set environment variable REV."
    else
      data = {'rev' => ENV['REV'], 'branch' => ENV['BRANCH'], 'status' => 'completed'}
      Opbeat::client.send_release(data)
    end
  end
end

