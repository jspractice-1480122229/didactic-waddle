function transcribe -d "Transcribe audio/video file using OpenAI Whisper (GPU-accelerated)"
    set -l usage "Usage: transcribe [--model MODEL] [--srt] [--batch] [FILE]
  transcribe recording.mp3              - Transcribe single file (small.en model)
  transcribe --model medium.en file.mp3 - Use a different model
  transcribe --srt file.webm            - Output SRT subtitle file alongside text
  transcribe --batch                    - Transcribe all media in current directory
  transcribe --srt --batch              - Batch with SRT output

Supported: mp3 wav m4a mp4 mkv webm ogg flac
Available models: tiny.en base.en small.en medium.en large-v3 turbo"

    if test (count $argv) -lt 1
        echo $usage
        return 1
    end

    set -l model "small.en"
    set -l do_srt 0
    set -l do_batch 0
    set -l target ""
    set -l whisper_dir "$HOME/Projects/whisper"

    set -l i 1
    while test $i -le (count $argv)
        switch $argv[$i]
            case --model
                set i (math $i + 1)
                set model $argv[$i]
            case --srt
                set do_srt 1
            case --batch
                set do_batch 1
            case '*'
                set target $argv[$i]
        end
        set i (math $i + 1)
    end

    if not test -d $whisper_dir
        echo "Error: Whisper project not found at $whisper_dir"
        return 1
    end

    # Build list of files to process
    set -l files
    if test $do_batch -eq 1
        for ext in mp3 wav m4a mp4 mkv webm ogg flac
            for f in *.$ext
                if test -f $f
                    set files $files (realpath $f)
                end
            end
        end
        if test (count $files) -eq 0
            echo "No supported media files found in current directory."
            return 1
        end
        echo "Batch transcribing "(count $files)" file(s) with model: $model"
    else if test -n "$target"
        if not test -f $target
            echo "Error: File not found: $target"
            return 1
        end
        set files (realpath $target)
        echo "Transcribing: $target (model: $model)"
    else
        echo $usage
        return 1
    end

    # Process each file inline (no inner function — avoids Fish scoping issues)
    for abspath in $files
        set -l base (string replace -r '\.[^.]+$' '' $abspath)

        if test -f "$base.txt"
            echo "Skipping "(basename $abspath)" — transcript already exists"
            continue
        end

        if test $do_batch -eq 1
            echo "Transcribing: "(basename $abspath)
        end

        set -l pyfile (mktemp /tmp/whisper_XXXXXX.py)

        if test $do_srt -eq 1
            echo "import whisper, os" > $pyfile
            echo "model = whisper.load_model(\"$model\")" >> $pyfile
            echo "result = model.transcribe(\"$abspath\", verbose=False)" >> $pyfile
            echo "base = os.path.splitext(\"$abspath\")[0]" >> $pyfile
            echo "open(base + '.txt', 'w').write(result['text'].strip())" >> $pyfile
            echo "def fmt(t):" >> $pyfile
            echo "    h,m=divmod(int(t),3600); m,s=divmod(m,60); ms=int((t%1)*1000)" >> $pyfile
            echo "    return f'{h:02}:{m:02}:{s:02},{ms:03}'" >> $pyfile
            echo "f=open(base+'.srt','w')" >> $pyfile
            echo "[f.write(f'{i}\n{fmt(s[\"start\"])} --> {fmt(s[\"end\"])}\n{s[\"text\"].strip()}\n\n') for i,s in enumerate(result['segments'],1)]" >> $pyfile
            echo "f.close()" >> $pyfile
            echo "print(result['text'].strip())" >> $pyfile
            echo "print(f'Saved: {base}.txt')" >> $pyfile
            echo "print(f'Saved: {base}.srt')" >> $pyfile
        else
            echo "import whisper, os" > $pyfile
            echo "model = whisper.load_model(\"$model\")" >> $pyfile
            echo "result = model.transcribe(\"$abspath\", verbose=False)" >> $pyfile
            echo "base = os.path.splitext(\"$abspath\")[0]" >> $pyfile
            echo "text = result['text'].strip()" >> $pyfile
            echo "open(base + '.txt', 'w').write(text)" >> $pyfile
            echo "print(text)" >> $pyfile
            echo "print(f'Saved: {base}.txt')" >> $pyfile
        end

        uv run --project $whisper_dir python $pyfile
        rm -f $pyfile
    end

    if test $do_batch -eq 1
        echo "Batch complete."
    end
end
