require 'shrine'
require 'shrine/storage/s3'

s3_options = {
  # Required
  region: Rails.application.credentials.s3["region"],
  bucket: Rails.application.credentials.s3["bucket"],
  access_key_id: Rails.application.credentials.aws["access_key_id"],
  secret_access_key: Rails.application.credentials.aws["secret_access_key"]
}

url_options = {
  public: true,
}

if Rails.env.test?
  require 'shrine/storage/memory'
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new
  }
else
  Shrine.storages = {
    cache: Shrine::Storage::S3.new(prefix: 'cache', upload_options: { acl: 'public-read' }, **s3_options),
    store: Shrine::Storage::S3.new(prefix: 'store', upload_options: { acl: 'public-read' }, **s3_options)
  }
end


Shrine.plugin :activerecord
Shrine.plugin :logging, logger: Rails.logger
Shrine.plugin :default_url_options, cache: url_options, store: url_options
Shrine.plugin :delete_raw, storages: [:store]
Shrine.plugin :presign_endpoint
Shrine.plugin :backgrounding

Shrine::Attacher.promote { |data| ShrineBackgrounding::PromoteJob.perform_async(data) }
Shrine::Attacher.delete { |data| ShrineBackgrounding::DeleteJob.perform_async(data) }