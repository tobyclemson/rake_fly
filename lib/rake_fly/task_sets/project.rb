require 'rake_factory'

require_relative '../tasks/authentication/login'
require_relative '../tasks/authentication/ensure'
require_relative '../tasks/pipeline/get'
require_relative '../tasks/pipeline/set'
require_relative '../tasks/pipeline/unpause'
require_relative '../tasks/pipeline/push'

module RakeFly
  module TaskSets
    class Project < RakeFactory::TaskSet
      prepend RakeFactory::Namespaceable

      parameter :argument_names, default: []

      parameter :concourse_url, required: true
      parameter :team, default: 'main'
      parameter :username
      parameter :password

      parameter :pipeline, required: true
      parameter :config, required: true

      parameter :vars
      parameter :var_files
      parameter :non_interactive

      parameter :target,
          default: RakeFactory::DynamicValue.new { |t| t.team }

      parameter :home_directory,
          default: RakeFactory::DynamicValue.new { |_| ENV['HOME'] }

      parameter :authentication_namespace, default: :authentication
      parameter :authentication_login_task_name, default: :login
      parameter :authentication_ensure_task_name, default: :ensure

      parameter :pipeline_namespace, default: :pipeline
      parameter :pipeline_get_task_name, default: :get
      parameter :pipeline_set_task_name, default: :set
      parameter :pipeline_unpause_task_name, default: :unpause
      parameter :pipeline_push_task_name, default: :push
      parameter :pipeline_destroy_task_name, default: :destroy

      parameter :fly_ensure_task_name, default: :'fly:ensure'

      task Tasks::Authentication::Login,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.authentication_login_task_name
          }
      task Tasks::Authentication::Ensure,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.authentication_ensure_task_name
          },
          login_task_name: RakeFactory::DynamicValue.new { |ts|
            ts.authentication_login_task_name
          }

      task Tasks::Pipeline::Get,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_get_task_name
          },
          authentication_ensure_task_name: RakeFactory::DynamicValue.new { |ts|
            (ts.authentication_namespace.to_s + ":" +
                ts.authentication_ensure_task_name.to_s)
                .to_sym
          }
      task Tasks::Pipeline::Set,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_set_task_name
          },
          authentication_ensure_task_name: RakeFactory::DynamicValue.new { |ts|
            (ts.authentication_namespace.to_s + ":" +
                ts.authentication_ensure_task_name.to_s)
                .to_sym
          }
      task Tasks::Pipeline::Unpause,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_unpause_task_name
          },
          authentication_ensure_task_name: RakeFactory::DynamicValue.new { |ts|
            (ts.authentication_namespace.to_s + ":" +
                ts.authentication_ensure_task_name.to_s)
                .to_sym
          }
      task Tasks::Pipeline::Push,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_push_task_name
          },
          get_task_name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_get_task_name
          },
          set_task_name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_set_task_name
          },
          unpause_task_name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_unpause_task_name
          }
      task Tasks::Pipeline::Destroy,
          name: RakeFactory::DynamicValue.new { |ts|
            ts.pipeline_destroy_task_name
          },
          authentication_ensure_task_name: RakeFactory::DynamicValue.new { |ts|
            (ts.authentication_namespace.to_s + ":" +
                ts.authentication_ensure_task_name.to_s)
                .to_sym
          }

      def define_on(application)
        around_define(application) do
          self.class.tasks.each do |task_definition|
            task_class = task_definition.klass.to_s
            ns = case task_class
            when /Pipeline/
              pipeline_namespace
            when /Authentication/
              authentication_namespace
            else
              raise StandardError.new(
                  "Unexpected task definition: #{task_class}.")
            end

            application.in_namespace(ns) do
              task_definition
                  .for_task_set(self)
                  .define_on(application)
            end
          end
        end
      end
    end
  end
end
