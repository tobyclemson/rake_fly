require 'ruby_fly'
require 'rake_factory'
require 'concourse'

module RakeFly
  module Tasks
    module Authentication
      class Login < RakeFactory::Task
        class FlyBackend
          def resolve_prerequisites(task)
            [task.ensure_task_name]
          end

          def execute(_)

          end
        end

        class ApiBackend
          def resolve_prerequisites(_)
            []
          end

          def execute(task)
            client = Concourse::Client.new(
                url: task.concourse_url)
            token = client.for_skymarshal.create_token(
                username: task.username,
                password: task.password)

            rc = RubyFly::RC.load(home: task.home_directory)
            rc.add_or_update_target(task.target) do |target|
              target.api = task.concourse_url
              target.team = task.team
              target.bearer_token = token.access_token
            end
            rc.write!
          end
        end

        default_name :login
        default_prerequisites RakeFactory::DynamicValue.new { |t|
          t.backend.new.resolve_prerequisites(t)
        }
        default_description RakeFactory::DynamicValue.new { |t|
          concourse_url = t.concourse_url || '<derived>'
          target = t.target || '<derived>'

          "Login to #{concourse_url} as target #{target}"
        }

        parameter :concourse_url, required: true
        parameter :team, default: 'main'
        parameter :target, required: true
        parameter :username
        parameter :password

        parameter :backend, default: ApiBackend

        parameter :home_directory,
            default: RakeFactory::DynamicValue.new { |_| ENV['HOME'] }

        parameter :ensure_task_name, :default => :'fly:ensure'

        action do |t|
          puts "Logging in to #{t.concourse_url} as target #{t.target}..."
          t.backend.new.execute(t)
        end
      end
    end
  end
end