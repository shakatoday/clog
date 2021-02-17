;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; CLOG - The Common Lisp Omnificent GUI                                 ;;;;
;;;; (c) 2020-2021 David Botton                                            ;;;;
;;;; License BSD 3 Clause                                                  ;;;;
;;;;                                                                       ;;;;
;;;; clog-gui.lisp                                                         ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(cl:in-package :clog)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementation - clog-gui - Desktop GUI abstraction
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconstant top-bar-height 20 "Overlap on new windows with nil set for top")

(defclass clog-gui ()
  ((body
    :accessor body
    :documentation "Top level access to browser window")
   (current-win
    :accessor current-win
    :initform nil
    :documentation "The current window at front")
   (windows
    :accessor windows
    :initform (make-hash-table :test 'equalp)
    :documentation "Window collection indexed by html-id")
   (last-z
    :accessor last-z
    :initform -9999
    :documentation "Top z-order for windows")
   (last-x
    :accessor last-x
    :initform 0
    :documentation "Last default open x point")
   (last-y
    :accessor last-y
    :initform 0
    :documentation "Last default open y point")
   (modal-background
    :accessor modal-background
    :initform nil
    :documentation "Modal Background")
   (in-drag
    :accessor in-drag
    :initform nil
    :documentation "Drag window or Size window")
   (drag-obj
    :accessor drag-obj
    :initform nil
    :documentation "Drag target object")
   (drag-x
    :accessor drag-x
    :documentation "Location of the left side or width relative to pointer during drag")
   (drag-y
    :accessor drag-y
    :documentation "Location of the top or height relative to pointer during drag")
   (menu
    :accessor menu
    :initform nil
    :documentation "Installed menu bar if installed")
   (window-select
    :accessor window-select
    :initform nil
    :documentation "If installed a drop down that selects window to maximize")
   (on-window-change
    :accessor on-window-change
    :initform nil
    :documentation "Fired when foreground window changed.")))

;;;;;;;;;;;;;;;;;;;;;
;; create-clog-gui ;;
;;;;;;;;;;;;;;;;;;;;;

(defun create-clog-gui (clog-body)
  "Create a clog-gui object and places it in CLOG-BODY's connection-data as
\"clog-gui\". (Private)"
  (let ((clog-gui (make-instance 'clog-gui)))
    (setf (connection-data-item clog-body "clog-gui") clog-gui)
    (setf (body clog-gui) clog-body)
    clog-gui))

;;;;;;;;;;;;;;;;;;;;;;;;;
;; clog-gui-initialize ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(defun clog-gui-initialize (clog-body &key (w3-css-url "/css/w3.css")
					(jquery-ui-css "/css/jquery-ui.css")
					(jquery-ui "/js/jquery-ui.js"))
  "Initializes clog-gui and installs a clog-gui object on connection."
  (create-clog-gui clog-body)
  (set-on-full-screen-change (html-document clog-body)
			     (lambda (obj)
			       (when (current-window obj)
				 (when (window-maximized-p (current-window obj))
				   (window-normalize (current-window obj))
				   (window-maximize (current-window obj))))))
  (set-on-orientation-change (window clog-body)
			     (lambda (obj)
			       (when (current-window obj)
				 (when (window-maximized-p (current-window obj))
				   (window-normalize (current-window obj))
				   (window-maximize (current-window obj))))))
  (when w3-css-url
    (load-css (html-document clog-body) w3-css-url))
  (when jquery-ui-css
    (load-css (html-document clog-body) jquery-ui-css))
  (when jquery-ui
    (load-script (html-document clog-body) jquery-ui)))

;;;;;;;;;;;;;;
;; menu-bar ;;
;;;;;;;;;;;;;;

(defgeneric menu-bar (clog-obj)
  (:documentation "Get/setf window menu-bar. This is set buy
create-gui-menu-bar."))

(defmethod menu-bar ((obj clog-obj))
  (let ((app (connection-data-item obj "clog-gui")))
    (menu app)))

(defgeneric set-menu-bar (clog-obj value)
  (:documentation "Set window menu-bar"))

(defmethod set-menu-bar ((obj clog-obj) value)
  (let ((app (connection-data-item obj "clog-gui")))
    (setf (menu app) value)))
(defsetf menu-bar set-menu-bar)

;;;;;;;;;;;;;;;;;;;;;
;; menu-bar-height ;;
;;;;;;;;;;;;;;;;;;;;;

(defgeneric menu-bar-height (clog-obj)
  (:documentation "Get menu-bar height"))

(defmethod menu-bar-height ((obj clog-obj))
  (let ((app (connection-data-item obj "clog-gui")))
    (if (menu app)
	(height (menu app))
	0)))

;;;;;;;;;;;;;;;;;;;;;;;
;; window-collection ;;
;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-collection (clog-obj)
  (:documentation "Get hash table of open windows"))

(defmethod window-collection ((obj clog-obj))
  (let ((app (connection-data-item obj "clog-gui")))
    (windows app)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; maximize-all-windows ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric maximize-all-windows (clog-obj)
  (:documentation "Maximize all windows"))

(defmethod maximize-all-windows ((obj clog-obj))
  (let ((app (connection-data-item obj "clog-gui")))
    (maphash (lambda (key value)
	       (declare (ignore key))
	       (window-maximize value))
	     (windows app))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; normalize-all-windows ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric normalize-all-windows (clog-obj)
  (:documentation "Normalize all windows"))

(defmethod normalize-all-windows ((obj clog-obj))
  (let ((app (connection-data-item obj "clog-gui")))
    (maphash (lambda (key value)
	       (declare (ignore key))
	       (window-normalize value))
	     (windows app))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementation - Menus
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-menu-bar ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass clog-gui-menu-bar (clog-div)()
  (:documentation "Menu bar"))

(defgeneric create-gui-menu-bar (clog-obj &key class html-id)
  (:documentation "Attached a menu bar to a CLOG-OBJ in general a
clog-body."))

(defmethod create-gui-menu-bar ((obj clog-obj)
				&key (class "w3-bar w3-black w3-card-4")
				  (html-id nil))
  (let ((div (create-div obj :class class :html-id html-id))
	(app (connection-data-item obj "clog-gui")))
    (change-class div 'clog-gui-menu-bar)
    (setf (menu app) div)
    div))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-menu-drop-down ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass clog-gui-menu-drop-down (clog-div)()
  (:documentation "Drop down menu"))

(defgeneric create-gui-menu-drop-down (clog-gui-menu-bar
				       &key content class html-id)
  (:documentation "Attached a menu bar drop-down to a CLOG-GUI-MENU-BAR"))

(defmethod create-gui-menu-drop-down ((obj clog-gui-menu-bar)
	          &key (content "")
		    (class "w3-dropdown-content w3-bar-block w3-card-4")
		    (html-id nil))
  (let* ((hover  (create-div obj :class "w3-dropdown-hover"))
	 (button (create-button hover :class "w3-button" :content content))
	 (div    (create-div hover :class class :html-id html-id)))
    (declare (ignore button))
    (change-class div 'clog-gui-menu-drop-down)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-menu-item ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass clog-gui-menu-item (clog-span)()
  (:documentation "Menu item"))

(defgeneric create-gui-menu-item (clog-gui-menu-drop-down
				  &key content
				    on-click
				    class
				    html-id)
  (:documentation "Attached a menu item to a CLOG-GUI-MENU-DROP-DOWN"))

(defmethod create-gui-menu-item ((obj clog-obj)
				 &key (content "")
				   (on-click nil)
				   (class "w3-bar-item w3-button")
				   (html-id nil))
  (let ((span
	  (create-span obj :content content :class class :html-id html-id)))
    (set-on-click span on-click)
    (change-class span 'clog-gui-menu-item)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-menu-item ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass clog-gui-menu-item (clog-span)()
  (:documentation "Menu item"))

(defgeneric create-gui-menu-item (clog-gui-menu-drop-down
				  &key content
				    on-click
				    class
				    html-id)
  (:documentation "Attached a menu item to a CLOG-GUI-MENU-DROP-DOWN"))

(defmethod create-gui-menu-item ((obj clog-obj)
				 &key (content "")
				   (on-click nil)
				   (class "w3-bar-item w3-button")
				   (html-id nil))
  (let ((span
	  (create-span obj :content content :class class :html-id html-id)))
    (set-on-click span on-click)
    (change-class span 'clog-gui-menu-item)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-menu-window-select ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass clog-gui-menu-window-select (clog-select)()
  (:documentation "Drop down containing windows. Selecting a window
will maximize it on top."))

(defgeneric create-gui-menu-window-select (clog-obj
					   &key class
					     html-id)
  (:documentation "Attached a clog-select as a menu item that auto updates
with open windows and maximizes them. Only one instance allowed."))

(defmethod create-gui-menu-window-select
    ((obj clog-obj)
     &key (class "w3-select")
       (html-id nil))
  (let ((window-select (create-select obj :class class :html-id html-id))
	(app           (connection-data-item obj "clog-gui")))
    (change-class window-select 'clog-gui-menu-window-select)
    (setf (window-select app) window-select)
    (set-on-change window-select (lambda (obj)
				   (let ((win (gethash (value obj) (windows app))))
				     (when win
				       (unless (keep-on-top win)
					 (window-maximize win))))))
    (create-option window-select :content "Select Window")
    window-select))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-menu-full-screen ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric create-gui-menu-full-screen (clog-gui-menu-bar &key html-id)
  (:documentation "Add as last item in menu bar to allow for a full screen
icon ⤢ and full screen mode."))

(defmethod create-gui-menu-full-screen ((obj clog-gui-menu-bar)
					&key (html-id nil))
  (create-child obj
    	  " <span class='w3-bar-item w3-right' style='user-select:none;'
	     onClick='if (document.fullscreenElement==null) {
                         documentElement.requestFullscreen()
                      } else {document.exitFullscreen();}'>⤢</span>"
	  :html-id html-id
	  :clog-type 'clog-gui-menu-item))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-menu-icon ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric create-gui-menu-icon (clog-gui-menu-bar &key image-url
						      on-click
						      class
						      html-id)
  (:documentation "Add icon as menu bar item."))

(defmethod create-gui-menu-icon ((obj clog-gui-menu-bar)
				 &key (image-url "/img/clogwicon.png")
				   (on-click nil)
				   (class "w3-button w3-bar-item")
				   (html-id nil))
  (set-on-click
   (create-child obj
		 (format nil "<button class='~A'>~
                                <img height=22 src='~A'></button>"
			 class
			 image-url)
		 :html-id html-id
		 :clog-type 'clog-gui-menu-item)
   on-click))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementation - Window System
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;
;; current-window ;;
;;;;;;;;;;;;;;;;;;;;

(defgeneric current-window (clog-obj)
  (:documentation "Get the current selected clog-gui-window"))

(defmethod current-window ((obj clog-obj))
  (let ((app (connection-data-item obj "clog-gui")))
    (current-win app)))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-change ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;
  
(defgeneric set-on-window-change (clog-obj handler)
  (:documentation "Set the on-window-change HANDLER.
The on-window-change clog-obj received is the new window"))

(defmethod set-on-window-change ((obj clog-obj) handler)
  (let ((app (connection-data-item obj "clog-gui")))
    (setf (on-window-change app) handler)))

(defmethod fire-on-window-change (obj app)
  "Fire handler if set. Change the value of current-win to clog-obj (Private)"
  (unless obj
    (let (new-order 
	  (order -9999))
      (maphash (lambda (key value)
		 (declare (ignore key))
		 (setf new-order (z-index value))
		 (when (>= new-order order)
		   (setf order new-order)
		   (setf obj value)))
	       (windows app))))
  (setf (current-win app) obj)
  (when (on-window-change app)
    (funcall (on-window-change app) obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementation - Individual Windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defclass clog-gui-window (clog-element)
  ((win-title
    :accessor win-title
    :documentation "Window title clog-element")
   (title-bar
    :accessor title-bar
    :documentation "Window title-bar clog-element")
   (content
    :accessor content
    :documentation "Window body clog-element")
   (closer
    :accessor closer
    :documentation "Window closer clog-element")
   (sizer
    :accessor sizer
    :documentation "Window sizer clog-element")
   (last-width
    :accessor last-width
    :initform nil
    :documentation "Last width before maximize")
   (last-height
    :accessor last-height
    :initform nil
    :documentation "Last heigth before maximize")
   (last-x
    :accessor last-x
    :initform nil
    :documentation "Last x before maximize")
   (last-y
    :accessor last-y
    :initform nil
    :documentation "Last y before maximize")
   (keep-on-top
    :accessor keep-on-top
    :initform nil
    :documentation "If t don't change z-order")
   (window-select-item
    :accessor window-select-item
    :initform nil
    :documentation "Item in window select")
   (on-window-can-close
    :accessor on-window-can-close
    :initform nil
    :documentation "Return t to allow close of window")
   (on-window-can-move
    :accessor on-window-can-move
    :initform nil
    :documentation "Return t to allow move of window")
   (on-window-can-size
    :accessor on-window-can-size
    :initform nil
    :documentation "Return t to allow close of window")
   (on-window-close
    :accessor on-window-close
    :initform nil
    :documentation "Fired on window closed")
   (on-window-move
    :accessor on-window-move
    :initform nil
    :documentation "Fired during move of window")
   (on-window-size
    :accessor on-window-size
    :initform nil
    :documentation "Fired during size change of window")
   (on-window-move-done
    :accessor on-window-move-done
    :initform nil
    :documentation "Fired after move of window")
   (on-window-size-done
    :accessor on-window-size-done
    :initform nil
    :documentation "Fired after size change of window")))

;;;;;;;;;;;;;;;;;;;;;;
;; on-gui-drag-down ;;
;;;;;;;;;;;;;;;;;;;;;;

(defun on-gui-drag-down (obj data)
  "Handle mouse down on drag items"
  (let ((app (connection-data-item obj "clog-gui")))
    (unless (in-drag app)
      (setf (in-drag app) (attribute obj "data-drag-type"))
      (let* ((target (gethash (attribute obj "data-drag-obj") (windows app)))
	     (pointer-x (getf data ':screen-x))
	     (pointer-y (getf data ':screen-y))
	     (obj-top)
	     (obj-left)
	     (perform-drag nil))
	(when target
	  (setf (drag-obj app) target)
	  (cond ((equalp (in-drag app) "m")
		 (setf obj-top
		       (parse-integer (top (drag-obj app)) :junk-allowed t))
		 (setf obj-left
		       (parse-integer (left (drag-obj app)) :junk-allowed t))
		 (setf perform-drag (fire-on-window-can-move (drag-obj app))))
		((equalp (in-drag app) "s")
		 (setf obj-top  (height (drag-obj app)))
		 (setf obj-left (width (drag-obj app)))
		 (setf perform-drag (fire-on-window-can-size (drag-obj app))))
		(t
		 (format t "Warning - invalid data-drag-type attribute")))
	  (unless (keep-on-top (drag-obj app))
	    (setf (z-index (drag-obj app)) (incf (last-z app))))
	  (fire-on-window-change (drag-obj app) app)
	  (setf (drag-y app) (- pointer-y obj-top))
	  (setf (drag-x app) (- pointer-x obj-left)))
	(cond (perform-drag
	       (set-on-pointer-move obj 'on-gui-drag-move)
	       (set-on-pointer-up obj 'on-gui-drag-stop))
	      (t
	       (setf (in-drag app) nil)))))))

;;;;;;;;;;;;;;;;;;;;;;
;; on-gui-drag-move ;;
;;;;;;;;;;;;;;;;;;;;;;

(defun on-gui-drag-move (obj data)
  "Handle mouse tracking on drag object"
  (let* ((app (connection-data-item obj "clog-gui"))
	 (x        (getf data ':screen-x))
	 (y        (getf data ':screen-y))
	 (adj-y    (- y (drag-y app)))
	 (adj-x    (- x (drag-x app))))
    (when (and (> adj-x 0) (> adj-y (menu-bar-height obj)))
      (cond ((equalp (in-drag app) "m")
	     (fire-on-window-move (drag-obj app))
	     (setf (top (drag-obj app)) (unit :px adj-y))
	     (setf (left (drag-obj app)) (unit :px adj-x)))
	    ((equalp (in-drag app) "s")
	     (fire-on-window-size (drag-obj app))
	     (setf (height (drag-obj app)) (unit :px adj-y))
	     (setf (width (drag-obj app)) (unit :px adj-x)))))))

;;;;;;;;;;;;;;;;;;;;;;
;; on-gui-drag-stop ;;
;;;;;;;;;;;;;;;;;;;;;;

(defun on-gui-drag-stop (obj data)
  "Handle end of drag object"
  (let ((app (connection-data-item obj "clog-gui")))
    (on-gui-drag-move obj data)
    (set-on-pointer-move obj nil)
    (set-on-pointer-up obj nil)
    (cond ((equalp (in-drag app) "m")
	   (fire-on-window-move-done (drag-obj app)))
	  ((equalp (in-drag app) "s")
	   (fire-on-window-size-done (drag-obj app))))
    (setf (in-drag app) nil)
    (setf (drag-obj app) nil)))

;;;;;;;;;;;;;;;;;;;;;;;
;; create-gui-window ;;
;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric create-gui-window (clog-obj &key title
					  content
					  left top width height
					  maximize
					  client-movement
					  html-id)
  (:documentation "Create a clog-gui-window. If client-movement is t then
use jquery-ui to move/resize and will not work on mobile. When client-movement
is t only on-window-move is fired once at start of drag and on-window-move-done
at end of drag and on-window-resize at start of resize and
on-window-resize-done at end of resize."))

(defmethod create-gui-window ((obj clog-obj) &key (title "New Window")
					       (content "")
					       (left nil)
					       (top nil)
					       (width 300)
					       (height 200)
					       (maximize nil)
					       (client-movement nil)
					       (html-id nil))
  (let ((app (connection-data-item obj "clog-gui")))
    (unless html-id
      (setf html-id (clog-connection:generate-id)))
    (when (eql (hash-table-count (windows app)) 0)
      ;; If previously no open windows reset default position
      (setf (last-x app) 0)
      (setf (last-y app) 0))
    (unless left
      ;; Generate sensible initial x location
      (setf left (last-x app))
      (incf (last-x app) 10))
    (unless top
      ;; Generate sensible initial y location
      (when (eql (last-y app) 0)
	(setf (last-y app) (menu-bar-height obj)))
      (setf top (last-y app))
      (incf (last-y app) top-bar-height)
      (when (> top (- (inner-height (window (body app))) (last-y app)))
	(setf (last-y app) (menu-bar-height obj))))
    (let ((win (create-child (body app)
			    (format nil
	    "<div style='position:fixed;top:~Apx;left:~Apx;width:~Apx;height:~Apx;
                  flex-container;display:flex;flex-direction:column;z-index:~A'
                  class='w3-card-4 w3-white w3-border'>
                  <div id='~A-title-bar' class='w3-container w3-black'
                       style='flex-container;display:flex;align-items:stretch;'>
                       <span data-drag-obj='~A' data-drag-type='m' id='~A-title'
                             style='flex-grow:9;user-select:none;cursor:move;'>~A</span>
                              <span id='~A-closer'
                                    style='cursor:pointer;user-select:none;'>&times;</span>
                  </div>
                  <div id='~A-body' style='flex-grow:9;overflow:auto'>~A</div>
                  <div id='~A-sizer' style='user-select:none;height:3px;
                       cursor:se-resize;opacity:0'
                       class='w3-right' data-drag-obj='~A' data-drag-type='s'>+</div>
             </div>"
	    top left width height (incf (last-z app)) ; outer div
	    html-id html-id html-id                   ; title bar
	    title html-id                             ; title
	    html-id content                           ; body
	    html-id html-id)                          ; size
			    :clog-type 'clog-gui-window
			    :html-id html-id)))
      (setf (win-title win)
	    (attach-as-child win (format nil "~A-title" html-id)))
      (setf (title-bar win)
	    (attach-as-child win (format nil "~A-title-bar" html-id)))
      (setf (closer win) (attach-as-child win (format nil "~A-closer" html-id)))
      (setf (sizer win) (attach-as-child win (format nil "~A-sizer" html-id)))
      (setf (content win) (attach-as-child win (format nil "~A-body"  html-id)))
      (setf (gethash (format nil "~A" html-id) (windows app)) win)
      (if maximize
	  (window-maximize win)
	  (fire-on-window-change win app))
      (when (window-select app)
	(setf (window-select-item win) (create-option (window-select app)
						      :content title
						      :value html-id)))      
      (set-on-double-click (win-title win) (lambda (obj)
					     (declare (ignore obj))
					     (window-toggle-maximize win)))
      (set-on-click (closer win) (lambda (obj)
				   (declare (ignore obj))
				   (when (fire-on-window-can-close win)
				     (window-close win))))
      (cond (client-movement
	     (jquery-execute win
			     (format nil "draggable({handle:'#~A-title-bar'})" html-id))
	     (jquery-execute win "resizable({handles:'se'})")
	     (set-on-pointer-down (win-title win)
	    			  (lambda (obj data)
				    (declare (ignore obj) (ignore data))
	    			    (setf (z-index win) (incf (last-z app)))
	    			    (fire-on-window-change win app)))
	     (set-on-event win "dragstart" 
			   (lambda (obj)
			     (declare (ignore obj))
			     (fire-on-window-move win)))
	     (set-on-event win "dragstop" 
			   (lambda (obj)
			     (declare (ignore obj))
			     (fire-on-window-move-done win)))
	     (set-on-event win "resizestart"
			   (lambda (obj)
			     (declare (ignore obj))
			     (fire-on-window-size win)))
	     (set-on-event win "resizestop" 
			   (lambda (obj)
			     (declare (ignore obj))
			     (fire-on-window-size-done win))))
	    (t
	     (set-on-pointer-down
	      (win-title win) 'on-gui-drag-down :capture-pointer t)
	     (set-on-pointer-down
	      (sizer win) 'on-gui-drag-down :capture-pointer t)))
      win)))

;;;;;;;;;;;;;;;;;;
;; window-title ;;
;;;;;;;;;;;;;;;;;;

(defgeneric window-title (clog-gui-window)
  (:documentation "Get/setf window title"))

(defmethod window-title ((obj clog-gui-window))
  (inner-html (win-title obj)))

(defgeneric set-window-title (clog-gui-window value)
  (:documentation "Set window title"))

(defmethod set-window-title ((obj clog-gui-window) value)
  (when (window-select-item obj)
    (setf (inner-html (window-select-item obj)) value))
  (setf (inner-html (win-title obj)) value))
(defsetf window-title set-window-title)

;;;;;;;;;;;;;;;;;;;;
;; window-content ;;
;;;;;;;;;;;;;;;;;;;;

(defgeneric window-content (clog-gui-window)
  (:documentation "Get window content element."))

(defmethod window-content ((obj clog-gui-window))
  (content obj))

;;;;;;;;;;;;;;;;;;
;; window-focus ;;
;;;;;;;;;;;;;;;;;;

(defgeneric window-focus (clog-gui-window)
  (:documentation "Set CLOG-GUI-WINDOW as focused window."))

(defmethod window-focus ((obj clog-gui-window))
  (let ((app (connection-data-item obj "clog-gui")))
    (when (keep-on-top obj)
      (setf (keep-on-top obj) nil))
    (setf (z-index obj) (incf (last-z app)))
    (fire-on-window-change obj app)))

;;;;;;;;;;;;;;;;;;
;; window-close ;;
;;;;;;;;;;;;;;;;;;

(defgeneric window-close (clog-gui-window)
  (:documentation "Close CLOG-GUI-WINDOW. on-window-can-close is not called."))

(defmethod window-close ((obj clog-gui-window))
  (let ((app (connection-data-item obj "clog-gui")))
    (remhash (format nil "~A" (html-id obj)) (windows app))
    (remove-from-dom (window-select-item obj))
    (remove-from-dom obj)
    (fire-on-window-change nil app)
    (fire-on-window-close obj)))

;;;;;;;;;;;;;;;;;;;;;;;;
;; window-maximized-p ;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-maximized-p (clog-gui-window)
  (:documentation "Set CLOG-GUI-WINDOW as maximized window."))

(defmethod window-maximized-p ((obj clog-gui-window))
  (last-width obj))

;;;;;;;;;;;;;;;;;;;;;
;; window-maximize ;;
;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-maximize (clog-gui-window)
  (:documentation "Set CLOG-GUI-WINDOW as maximized window."))

(defmethod window-maximize ((obj clog-gui-window))
  (let ((app (connection-data-item obj "clog-gui")))
    (window-focus obj)
    (unless (window-maximized-p obj)
      (setf (last-x obj) (left obj))
      (setf (last-y obj) (top obj))
      (setf (last-height obj) (height obj))
      (setf (last-width obj) (width obj))
      (setf (top obj) (unit :px (menu-bar-height obj)))
      (setf (left obj) (unit :px 0))
      (setf (width obj) (unit :vw 100))
      (setf (height obj)
	    (- (inner-height (window (body app))) (menu-bar-height obj)))
      (fire-on-window-size-done obj))))

;;;;;;;;;;;;;;;;;;;;;;
;; window-normalize ;;
;;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-normalize (clog-gui-window)
  (:documentation "Set CLOG-GUI-WINDOW as normalized window."))

(defmethod window-normalize ((obj clog-gui-window))
  (window-focus obj)
  (when (window-maximized-p obj)
    (setf (width obj) (last-width obj))
    (setf (height obj) (last-height obj))
    (setf (top obj) (last-y obj))
    (setf (left obj) (last-x obj))
    (setf (last-width obj) nil)
    (fire-on-window-size-done obj)))

;;;;;;;;;;;;;;;;;;;;;;;;
;; window-keep-on-top ;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-keep-on-top (clog-gui-window)
  (:documentation "Set CLOG-GUI-WINDOW to stay on top. Use window-focus to undue."))

(defmethod window-keep-on-top ((obj clog-gui-window))
  (setf (keep-on-top obj) t)
  (setf (z-index obj) 1))

;;;;;;;;;;;;;;;;;;;;;;;
;; window-make-modal ;;
;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-make-modal (clog-gui-window)
  (:documentation "Set CLOG-GUI-WINDOW to stay on top and prevent all other
interactions. Use window-end-modal to undo."))

(defmethod window-make-modal ((obj clog-gui-window))
  (let ((app (connection-data-item obj "clog-gui")))
    (setf (modal-background app) (create-div (body app) :class "w3-overlay"))
    (setf (display (modal-background app)) :block)
    (setf (keep-on-top obj) t)
    (setf (z-index obj) 4)))

;;;;;;;;;;;;;;;;;;;;;;
;; window-end-modal ;;
;;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-end-modal (clog-gui-window)
  (:documentation "Set CLOG-GUI-WINDOW to end modal state."))

(defmethod window-end-modal ((obj clog-gui-window))
  (let ((app (connection-data-item obj "clog-gui")))
    (remove-from-dom (modal-background app))
    (window-focus obj)))
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; window-toggle-maximize ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric window-toggle-maximize (clog-gui-window)
  (:documentation "Toggle CLOG-GUI-WINDOW as maximize window."))

(defmethod window-toggle-maximize ((obj clog-gui-window))
  (let ((app (connection-data-item obj "clog-gui")))
    (window-focus obj)
    (cond ((window-maximized-p obj)
	   (setf (width obj) (last-width obj))
	   (setf (height obj) (last-height obj))
	   (setf (top obj) (last-y obj))
	   (setf (left obj) (last-x obj))
	   (setf (last-width obj) nil))
	  (t
	   (setf (last-x obj) (left obj))
	   (setf (last-y obj) (top obj))
	   (setf (last-height obj) (height obj))
	   (setf (last-width obj) (width obj))
	   (setf (top obj) (unit :px (menu-bar-height obj)))
	   (setf (left obj) (unit :px 0))
	   (setf (width obj) (unit :vw 100))
	   (setf (height obj)
		 (- (inner-height (window (body app))) (menu-bar-height obj)))))
    (fire-on-window-size-done obj)))
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-can-close ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-can-close (clog-gui-window handler)
  (:documentation "Set the on-window-can-close HANDLER"))

(defmethod set-on-window-can-close ((obj clog-gui-window) handler)
  (setf (on-window-can-close obj) handler))

(defgeneric fire-on-window-can-close (clog-gui-window)
  (:documentation "Fire handler if set. (Private)"))

(defmethod fire-on-window-can-close ((obj clog-gui-window))
  (if (on-window-can-close obj)
      (funcall (on-window-can-close obj) obj)
      t))

;;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-close ;;
;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-close (clog-gui-window handler)
  (:documentation "Set the on-window-close HANDLER"))

(defmethod set-on-window-close ((obj clog-gui-window) handler)
  (setf (on-window-close obj) handler))

(defgeneric fire-on-window-close (clog-gui-window)
  (:documentation "Fire handler if set. (Private)"))

(defmethod fire-on-window-close ((obj clog-gui-window))
  (when (on-window-close obj)
    (funcall (on-window-close obj) obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-can-size ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-can-size (clog-gui-window handler)
  (:documentation "Set the on-window-can-size HANDLER"))

(defmethod set-on-window-can-size ((obj clog-gui-window) handler)
  (setf (on-window-can-size obj) handler))

(defgeneric fire-on-window-can-size (clog-gui-window)
  (:documentation "Fire handler if set. (Private)"))

(defmethod fire-on-window-can-size ((obj clog-gui-window))
  (if (on-window-can-size obj)
      (funcall (on-window-can-size obj) obj)
      t))

;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-size ;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-size (clog-gui-window handler)
  (:documentation "Set the on-window-size HANDLER"))

(defmethod set-on-window-size ((obj clog-gui-window) handler)
  (setf (on-window-size obj) handler))

(defgeneric fire-on-window-size (clog-gui-window)
  (:documentation "Fire handler if set. (Private)"))

(defmethod fire-on-window-size ((obj clog-gui-window))
  (when (on-window-size obj)
    (funcall (on-window-size obj) obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-size-done ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-size-done (clog-gui-window handler)
  (:documentation "Set the on-window-size-done HANDLER"))

(defmethod set-on-window-size-done ((obj clog-gui-window) handler)
  (setf (on-window-size-done obj) handler))

(defmethod fire-on-window-size-done ((obj clog-gui-window))
  (when (on-window-size-done obj)
    (funcall (on-window-size-done obj) obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-can-move ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-can-move (clog-gui-window handler)
  (:documentation "Set the on-window-can-move HANDLER"))

(defmethod set-on-window-can-move ((obj clog-gui-window) handler)
  (setf (on-window-can-move obj) handler))

(defgeneric fire-on-window-can-move (clog-gui-window)
  (:documentation "Fire handler if set. (Private)"))

(defmethod fire-on-window-can-move ((obj clog-gui-window))
  (if (on-window-can-move obj)
      (funcall (on-window-can-move obj) obj)
      t))

;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-move ;;
;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-move (clog-gui-window handler)
  (:documentation "Set the on-window-move HANDLER"))

(defmethod set-on-window-move ((obj clog-gui-window) handler)
  (setf (on-window-move obj) handler))

(defgeneric fire-on-window-move (clog-gui-window)
  (:documentation "Fire handler if set. (Private)"))

(defmethod fire-on-window-move ((obj clog-gui-window))
  (when (on-window-move obj)
    (funcall (on-window-move obj) obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; set-on-window-move-done ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defgeneric set-on-window-move-done (clog-gui-window handler)
  (:documentation "Set the on-window-move-done HANDLER"))

(defmethod set-on-window-move-done ((obj clog-gui-window) handler)
  (setf (on-window-move-done obj) handler))

(defmethod fire-on-window-move-done ((obj clog-gui-window))
  (when (on-window-move-done obj)
    (funcall (on-window-move-done obj) obj)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Implementation - Dialog Boxes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun server-file-dialog (obj title initial-dir on-file-name
			   &key (left nil) (top nil) (width 400) (height 375)
			     (maximize nil)
			     (initial-filename nil))
  "Create a local file dialog box called TITLE using INITIAL-DIR on server
machine, upon close ON-FILE-NAME called with filename or nil if failure."
  (let* ((win    (create-gui-window obj
				   :title    title
				   :maximize maximize
				   :top      top
				   :left     left
				   :width    width
				   :height   height))
	 (box    (create-div (window-content win) :class "w3-panel"))
	 (form   (create-form box))
	 (dirs   (create-select form))
	 (files  (create-select form))
	 (input  (create-form-element form :input :label
				     (create-label form :content "File Name:")))
	 (ok     (create-button form :content "OK"))
	 (cancel (create-button form :content "Cancel")))
    (setf (size dirs) 4)
    (setf (box-width dirs) "100%")
    (setf (size files) 8)
    (setf (box-width files) "100%")
    (setf (box-width input) "100%")
    (setf (width ok) "7em")
    (setf (width cancel) "7em")
    (window-make-modal win)
    (flet ((populate-dirs (dir)
	     (setf (inner-html dirs) "")
	     (add-select-option dirs (format nil "~A" dir) ".")
	     (setf (value input) (truename dir))
	     (unless (or (equalp dir "/") (equalp dir #P"/"))
	       (add-select-option dirs (format nil "~A../" dir) ".."))
	     (dolist (item (uiop:subdirectories dir))
	       (add-select-option dirs item item)))
	   (populate-files (dir)
	     (setf (inner-html files) "")
	     (dolist (item (uiop:directory-files dir))
	       (add-select-option files item (file-namestring item))))
	   (caret-at-end ()
	     (focus input)
	     (js-execute win (format nil "~A.setSelectionRange(~A.value.length,~A.value.length)"
				     (clog::script-id input)
				     (clog::script-id input)
				     (clog::script-id input)))))
      (populate-dirs initial-dir)
      (populate-files initial-dir)
      (when initial-filename
	(setf (value input) (truename initial-filename))
	(caret-at-end))
      (set-on-change files (lambda (obj)
			     (declare (ignore obj))
			     (setf (value input) (truename (value files)))
			     (caret-at-end)))
      (set-on-change dirs (lambda (obj)
			    (declare (ignore obj))
			    (setf (value input) (value dirs))
			    (caret-at-end)
			    (populate-files (value dirs))))
      (set-on-double-click dirs
			   (lambda (obj)
			     (declare (ignore obj))
			     (populate-dirs (truename (value dirs)))))
      (set-on-double-click files (lambda (obj)
				   (declare (ignore obj))
				   (click ok))))
    (set-on-window-close win (lambda (obj)
			       (declare (ignore obj))
			       (window-end-modal win)
			       (funcall on-file-name nil)))
    (set-on-click cancel (lambda (obj)
			   (declare (ignore obj))
			   (window-close win)))
    (set-on-click ok (lambda (obj)
		       (declare (ignore obj))
		       (set-on-window-close win nil)
		       (window-end-modal win)
		       (window-close win)
		       (funcall on-file-name (value input))))))