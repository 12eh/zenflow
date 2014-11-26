module Zenflow
  module BranchCommands
    module Publish

      def self.included(thor)
        thor.class_eval do

          desc "publish [NAME]", "Publish a branch"
          def publish
            publish_branch
          end

          no_commands do
            def publish_branch
              Zenflow::Branch.push("#{flow}/#{branch_name}")
              Zenflow::Branch.track("#{flow}/#{branch_name}")
            end
          end

        end
      end

    end
  end
end
