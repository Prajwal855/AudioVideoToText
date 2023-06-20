class VideoSerializer
  include FastJsonapi::ObjectSerializer
  attributes :id, :video_file, :to_string
  
  include Rails.application.routes.url_helpers

  def video_file
    rails_blob_path(object.video_file, only_path: true) if object.video_file.attached?
  end

  def to_string
    object.to_string
  end
end
