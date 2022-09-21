# cronotab.rb — Crono configuration file
#
# Here you can specify periodic jobs and schedule.
# You can use ActiveJob's jobs from `app/jobs/`
# You can use any class. The only requirement is that
# class should have a method `perform` without arguments.
#
class CalculateAllTaskJob
  def perform
    DispatchServer.new.execute({project_name: '_all'})
  end
end

Crono.perform(CalculateAllTaskJob).every 1.week, on: :sunday, at: "09:30"