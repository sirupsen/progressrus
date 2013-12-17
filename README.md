# Progressrus

`Progressrus` provides progress status of long-running jobs. The progress is
stored in some kind of database. Progressrus currently ships with a Redis
adapter. Think of it as a progress bar where instead of flushing the progress to
`stdout`, it's stored in a data store. It can be used with a background job engine or
just about anything where you need to show the progress in a different location
than the long-running operation.

It works by instructing `Progressrus` about the finishing point. When the job
makes progress towards the total, the job calls `tick`. With ticks 2 seconds
apart (configurable) the progress is updated in the data store. This prevents a
job processing e.g. 100 records to hit the data store 100 times. Combination of
adapters is planned, so you can publish to some kind of real-time data source,
Redis and even stdout at the same time.

`Progressrus` keeps track of the jobs in some scope. This could be a `user_id`.
This makes it easy to find the jobs and their progress for a specific user,
without worrying about keeping e.g. the Resque job ids around.

`Progressrus` will update the data store with the progress of the job. The key
for a user with `user_id` `3421` would be: `progressrus:user:3421`. For the
Redis data store, the key is a Redis hash where the Redis `job_id` is the key
and the value is a `json` object with information about the progress, i.e.:

```redis
redis> HGETALL progressrus:user:3421
1) "4bacc11a-dda3-405e-b0aa-be8678d16037"
2) "{"count\":94,\"total\":100,\"started_at\":\"2013-12-08 10:53:41 -0500\"}"
```

## Usage

Instrument by creating a `Progressrus` object with the `scope` and `total` amount of
records to be processed:

```ruby
class MaintenacegProcessRecords
  def self.perform(record_ids, user_id)
    # Construct the pace object.
    progress = Progresserus.new(scope: [:user, user_id], total: record_ids.count)

    # Start processing the records!
    Record.where(id: record_ids).find_each do |record|
      record.do_expensive_things

      # Does a single tick, updates the data store every x seconds this is called.
      progress.tick
    end

    # Force an update to the data store and set :completed_at to Time.now
    progress.complete
  end
end
```

## Querying Ticks by scope

To query for the progress of jobs for a specific scope:

```ruby
> Progressrus.all(["walrus", '1234'])
#=> [
  #<Progressrus::Progress:0x007f0fdc8ab888 @scope=["walrus", "1234"], @total=50, @id="narwhal", @interval=2, @params={:count=>0, :started_at=>"2013-12-12 18:09:44 +0000", :completed_at=>nil, :name=>"oemg-test-2"}, @count=0, @started_at=2013-12-12 18:09:44 +0000, @persisted_at=2013-12-12 18:09:41 +0000, @store=#<Progressrus::Store::Redis:0x007f0fdc894c28 @redis=#<Redis client v3.0.6 for redis://127.0.0.1:6379/0>, @options={:expire=>1800, :prefix=>"progressrus"}>, @completed_at=nil>,
  #<Progressrus::Progress:0x007f0fdc8ab4a0 @scope=["walrus", "1234"], @total=100, @id="oemg", @interval=2, @params={:count=>0, :started_at=>"2013-12-12 18:09:44 +0000", :completed_at=>nil, :name=>"oemg-test"}, @count=0, @started_at=2013-12-12 18:09:44 +0000, @persisted_at=2013-12-12 18:09:41 +0000, @store=#<Progressrus::Store::Redis:0x007f0fdc894c28 @redis=#<Redis client v3.0.6 for redis://127.0.0.1:6379/0>, @options={:expire=>1800, :prefix=>"progressrus"}>, @completed_at=nil>
]
```

The `Progressrus` objects contain useful methods such as `#percentage` to return how
many percent done the job is and `#eta` to return a `Time` object estimation of
when the job will be complete.  The scope is completely independent from the job
itself, which means you can have jobs from multiple sources in the same scope.

## Querying Progress by scope and id

To query for the progress of a specific job:

```ruby
> Progressrus.find(["walrus", '1234'], 'narwhal')
#=> #<Progressrus::Progress:0x007f0fdc8ab888 @scope=["walrus", "1234"], @total=50, @id="narwhal", @interval=2, @params={:count=>0, :started_at=>"2013-12-12 18:09:44 +0000", :completed_at=>nil, :name=>"oemg-test-2"}, @count=0, @started_at=2013-12-12 18:09:44 +0000, @persisted_at=2013-12-12 18:09:41 +0000, @store=#<Progressrus::Store::Redis:0x007f0fdc894c28 @redis=#<Redis client v3.0.6 for redis://127.0.0.1:6379/0>, @options={:expire=>1800, :prefix=>"progressrus"}>, @completed_at=nil>
```

## Todo

* Tighter Resque/Sidekiq/DJ integration
* Rack interface
* SQL adapter
* Document adapter-specific options
