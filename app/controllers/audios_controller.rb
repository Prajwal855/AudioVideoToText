class AudiosController < ApplicationController
    def index
        audios = current_user.audios
        if audio.empty?
            render json:{
            message: "Audios not Found For Current User",
            user: current_user,
            audio_transcrptions: []
            }, status: :not_found
        else
            render json:{
                message: "Successfully rendered all the audios of the current user",
                user: current_user,
                audio_transcrptions: audios
            }, status: :ok
        end
      end
    
      def show
        if audio
          render json:{
            message: "Rendered the audio with the ID: #{params[:id]}",
            user: current_user,
            audio_file: audio_file,
            audio_url: audio_url,
            transcription: audio.to_string
          }, status: :ok
        else
          render json:{
            message: "Unable to get the audio with the given ID: #{params[:id]}",
            error: audio.error.full_messages,
            user: current_user
          }, status: :unprocessable_entity
        end
      end
    
    
      def create
        flagged_words = ['samsung', 'guy', 'apple']
        audio = current_user.audio.create(audio_params)
        audio.save
    
        active_storage_disk_service = ActiveStorage::Service::DiskService.new(root: Rails.root.to_s + '/storage/')
        audio_file = active_storage_disk_service.send(:path_for, audio.audio_file.blob.key)
    
    
        audio_service = TranscriptionService.new()
        transcription = audio_service.upload(audio_file)
    
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
    
        audio.update(to_string: transcription)
    
        if audio
          render json:{
            message: "Successfully added the audio to the signed in user.",
            user: current_user,
            audio_file: audio_file,
            audio_url: audio_url,
            transcribed_text: @audio.to_string
          },status: :created
        else
          render json:{
            message: audio.errors.full_messages
          },status: :unprocessable_entity
        end
      end
    
    
      def destroy
        if audio.destroy
          render json:{
            message: "Removed the audio with id #{params[:id]}",
            user: current_user
          }, status: :ok
        else
          render json:{
            message: "Error while removing the audio.",
            error: audio.error.full_messages,
            user: current_user
          }, status: :unprocessable_entity
        end
      end
    
      private
        def set_audio
          audio = current_user.audios.find(params[:id])
          audio_url = AudioSerializer.new(audio).audio_file
        end
    
        def audio_params
          params.permit(:audio_file)
        end
end
