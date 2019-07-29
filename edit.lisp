(require :sb-posix)

;; TODO:
;; - Hide the cursor while drawing / refreshing the screen.
;; - Write updates to a buffer and then write them to the terminal in
;;   one go.
;; - Redraw lines one at a time rather than in one big refresh.
;; - Figure out how to draw a welcome message.
;; - Add cursor state.
;; - Add key movements for the cursor.
;; - Allow the input of text.

(defparameter quit-key #\Dc1) ; Use C-q to quit.

(defun read-key (input-stream)
  (let ((key (read-char input-stream nil)))
    (if key
	key
	(read-key input-stream))))

(defun clear-screen (output-stream)
  (write-string "[2J" output-stream) ; Clear screen.
  (write-string "[H" output-stream)  ; Move cursor to 1, 1.
  (finish-output output-stream))

(defun process-key (input-stream)
  (let ((key (read-key input-stream)))
    (cond ((char= key quit-key) (progn (clear-screen t) (exit)))
	  (t nil))))

(defun refresh-screen (output-stream cols)
  (write-string "[2J" output-stream) ; Clear screen.
  (write-string "[H" output-stream)  ; Move cursor to 1, 1.
  (dotimes (n cols)
    (write-string "~" output-stream)
    (when (< n (- cols 1)) ; Don't print \r\n on the last line.
      (write-string (format nil "~C~C" #\return #\linefeed) output-stream)))
  (write-string "[H" output-stream)  ; Move cursor to 1, 1.
  (finish-output output-stream))

(sb-alien:define-alien-type nil
    (sb-alien:struct winsize
		     (ws_row sb-alien:unsigned-short)
		     (ws_col sb-alien:unsigned-short)
		     (ws_xpixel sb-alien:unsigned-short)
		     (ws_ypixel sb-alien:unsigned-short)))

(defconstant +tiocgwinsz+ #x5413)

(defun termsize ()
  (let ((window (sb-alien:make-alien (struct winsize))))
    (sb-posix:ioctl sb-sys:*stdin* +tiocgwinsz+ window)
    (values (sb-alien:slot window 'ws_col)
	    (sb-alien:slot window 'ws_row))))

(defun main ()
  (let ((old-tm (sb-posix:tcgetattr sb-sys:*tty*))
	(new-tm (sb-posix:tcgetattr sb-sys:*tty*)))
    (unwind-protect
	 (progn
	   (setf (sb-posix:termios-iflag new-tm)
	   	 (logand (sb-posix:termios-iflag new-tm)
			 (lognot (logior sb-posix:ixon
					 sb-posix:icrnl
					 sb-posix:brkint
					 sb-posix:inpck
					 sb-posix:istrip))))
	   (setf (sb-posix:termios-oflag new-tm)
		 (logand (sb-posix:termios-oflag new-tm)
			 (lognot sb-posix:opost)))
	   (setf (sb-posix:termios-cflag new-tm)
	   	 (logior (sb-posix:termios-cflag new-tm) sb-posix:cs8))

	   (setf (sb-posix:termios-lflag new-tm)
		 (logand (sb-posix:termios-lflag new-tm)
			 (lognot (logior sb-posix:echo
					 sb-posix:icanon
					 sb-posix:isig
					 sb-posix:iexten))))
	   (setf (aref (sb-posix:termios-cc new-tm) sb-posix:vmin) 0)
	   (setf (aref (sb-posix:termios-cc new-tm) sb-posix:vtime) 1)
	   ;; Set a bunch of terminal attrs to make it behaves as a
	   ;; text editor.
	   (sb-posix:tcsetattr sb-sys:*tty* sb-posix:tcsaflush new-tm)
	   ;; TODO: (multiple-value-bind (cols rows) (termsize)
	   (let ((cols (termsize)))
	     ;; The main loop of the text editor.
	     (loop
		(refresh-screen t cols)
		(process-key t))))
      ;; Reset to the old attrs on exit.
      (sb-posix:tcsetattr sb-sys:*tty* sb-posix:tcsaflush old-tm))))
