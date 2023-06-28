class VideosController < ApplicationController
    def index
        videos = current_user.videos
        if videos.empty?
            render json: {
                message: "User Does Not have any Videos",
                user: current_user,
                video_transcrptions: []
            }, status: :not_found
        else
            render json:{
          message: "Successfully rendered all the videos of the current user",
          user: current_user,
          video_transcrptions: videos
        }, status: :ok
        end
    end
    
      def show
        if video
          render json:{
            message: "Rendered the video with the ID: #{params[:id]}",
            user: current_user,
            video_file: video_file,
            video_url: video_url,
            transcription: video.to_string
          }, status: :ok
        else
          render json:{
            message: "Unable to get the video with the given ID: #{params[:id]}",
            error: video.error.full_messages,
            user: current_user
          }, status: :unprocessable_entity
        end
      end
    
    
      def create
        flagged_words = ['shit', 'iphone', 'apple']
        video = current_user.videos.create(video_params)
        video.save
    
        active_storage_disk_service = ActiveStorage::Service::DiskService.new(root: Rails.root.to_s + '/storage/')
        video_file = active_storage_disk_service.send(:path_for, video.video_file.blob.key)
    
    
        video_service = TranscriptionService.new()
        transcription = video_service.upload(video_file)
    
        transcribed_words = transcription.split(/\W+/).to_a
    
        for word in transcribed_words
          if flagged_words.include?(word.downcase)
            current_user.flagged_words_count += 1
            current_user.save()
          end
        end
    
        if current_user.flagged_words_count >= 3
          current_user.blocked = true
          current_user.save()
        end
    
        video.update(to_string: transcription)
    
        if video
          render json:{
            message: "Successfully added the video to the signed in user.",
            user: current_user,
            video_file: video_file,
            video_url: video_url,
            transcribed_text: video.to_string
          },status: :created
        else
          render json:{
            message: video.errors.full_messages
          },status: :unprocessable_entity
        end
      end
    
    
      def destroy
        if video.destroy
          render json:{
            message: "Removed the video with id #{params[:id]}",
            user: current_user
          }, status: :ok
        else
          render json:{
            message: "Error while removing the video.",
            error: video.error.full_messages,
            user: current_user
          }, status: :unprocessable_entity
        end
      end
    
      private
        def set_video
          video = current_user.videos.find(params[:id])
          video_url = VideoSerializer.new(video).video_file
        end
        
        def video_params
          params.permit(:video_file)
        end
end
