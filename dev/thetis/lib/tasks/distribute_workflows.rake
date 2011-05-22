# rake thetis:distribute_workflows RAILS_ENV=production

namespace :thetis do
  task :distribute_workflows, :needs => [:environment] do

    workflows = Workflow.find(:all)

    unless workflows.nil?
      workflows.each do |workflow|
        if workflow.decided_at.nil? and workflow.decided?

          last_comment = workflow.get_last_comment
          unless last_comment.nil?
            workflow.update_attribute(:decided_at, last_comment.updated_at)
          end

          workflow.distribute_cc
        end
      end
    end
  end
end
