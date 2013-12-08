# RedisProgress

`RedisProgress` provides progress status of long-running jobs. The
progress is stored in Redis. Think of it as a progress bar where instead of
flushing the progress to `stdout`, it's stored in Redis. It can be used with a
background job engine or just about anything where you need to show the progress
in a different location.

It works by instructing `RedisProgress` about the finishing point. For each
progress, the job calls `tick`. `RedisProgress` figures out when it's
appropriate to update the progress of the job. Two conditions must hold for
`RedisProgress` to update the job:

1. 2 seconds or more should have passed since last time the status was updated.
   This prevents a job processing relatively e.g. 100 records to hit Redis 100
   times. Updating more than every two seconds doesn't really provide much
   value.
2. When the percentage changes, i.e. `10%` to `11%`.

`RedisProgress` keeps track of the jobs in some scope. This could be a `user_id`.
This makes it easy to find the jobs and their progress for a specific user.

Once one of the two conditions above are true, `RedisProgress` will update Redis
with the progress of the job. The key for a user with `user_id` `3421` would be:
`resque:pace:3421`. This Redis key is a Redis hash where the Redis `job_id` is
the key and the value is a `json` object with information about the progress,
i.e.: 

```redis
redis> HGETALL resque:pace:user:3421
1) "4bacc11a-dda3-405e-b0aa-be8678d16037"
2) "{\"percent\":94,\"count\":94,\"total\":100,\"started_at\":\"2013-12-08
    10:53:41 -0500\",\"estimated_finished_at\":\"2013-12-08 10:55:19
    -0500\",\"finished_at\":null}""
```

Instrument by creating a `Pace` object with the `scope` and `total` amount of
records to be processed:

```ruby
class MaintenacegProcessRecords
  def self.perform(record_ids, user_id)
    # Construct the pace object. This also creates the 0% marker.
    pace = RedisProgress.new(scope: [:user, user_id], total: record_ids.count)
    
    # Start processing the records!
    Record.where(id: record_ids).find_each do |record|
      record.do_expensive_things

      # Does a single tick, updates Redis when 1. and 2. hold.
      pace.tick!
    end
  end
end
```

To query the pace of jobs for a specific scope: 

```ruby
> RedisProgress.jobs(scope: ["user", user_id]
#=> {
  # Auto-generated id for the Job by RedisProgress
  "4bacc11a-dda3-405e-b0aa-be8678d16037" => {
    :percent=>94, 
    :count=>94,
    :total=>100, 
    :started_at=>2013-12-08 10:53:41 -0500, 
    :estimated_finished_at=>2013-12-08 10:55:19 -0500,
    :finished_at=>nil
  }
}
```

## Installation

Add this line to your application's Gemfile:

    gem 'resque-pace'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resque-pace

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
