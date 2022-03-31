# Installing Common Lisp on Windows 64bit from Scratch

1. Download and install rho-emacs
	https://gchristensen.github.io/rho-emacs/

      When installing choose C:\Users\_yourname_ for the "home folder"

      I like a plain emacs, others like the various default extensions and themes.

2. Install sbcl
	http://prdownloads.sourceforge.net/sbcl/sbcl-2.2.2-x86-64-windows-binary.msi

3. Get Git 64 bit - even if you don't use GIT installs the needed ssl files
and some basic unix tools like bash
     https://git-scm.com/download/win

4. Get the 64 bit SQLite DLL from
     https://www.sqlite.org/download.html
Double clip the downloaded dll zip and copy the file to C:\Program Files\Git\mingw64\bin

5. Download QuickLisp
	Download using http://beta.quicklisp.org/quicklisp.lisp
      (assuming downloaded to Downloads)

6. Install QuickLisp
      Open Git Bash and run: sbcl
      
      Use the mouse right click paste or type:
      At the * prompt from sbcl type: (load "~/Downloads/quicklisp.lisp")
      At the * prompt from sbcl type: (quicklisp-quickstart:install)
      At the * prompt from sbcl type: (ql:add-to-init-file)
      At the * prompt from sbcl type: (ql:quickload :quicklisp-slime-helper)
      At the * prompt from sbcl type: (quit)

      run rho emacs with (I would add to path or make a script):
      /c/Program\ Files/rho-emacs/rho

      Use C-x-f and create the file ~/.emacs.d/init.el and add the next two lines:

      (load (expand-file-name "C:/Users/david/quicklisp/slime-helper.el"))
      (setq inferior-lisp-program "sbcl")

       Quit emacs - C-x C-y

7. Install CLOG
      Start again emacs
      /c/Program\ Files/rho-emacs/rho

      Run Slime - M-x slime
      (ql:quickload :clog)