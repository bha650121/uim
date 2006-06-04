;;  Filename : test-define.scm
;;  About    : unit test for R5RS 'define'
;;
;;  Copyright (C) 2005-2006 Kazuki Ohta <mover AT hct.zaq.ne.jp>
;;
;;  All rights reserved.
;;
;;  Redistribution and use in source and binary forms, with or without
;;  modification, are permitted provided that the following conditions
;;  are met:
;;
;;  1. Redistributions of source code must retain the above copyright
;;     notice, this list of conditions and the following disclaimer.
;;  2. Redistributions in binary form must reproduce the above copyright
;;     notice, this list of conditions and the following disclaimer in the
;;     documentation and/or other materials provided with the distribution.
;;  3. Neither the name of authors nor the names of its contributors
;;     may be used to endorse or promote products derived from this software
;;     without specific prior written permission.
;;
;;  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS
;;  IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
;;  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
;;  PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR
;;  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;;  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;;  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;;  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
;;  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;;  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;;  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(load "./test/unittest.scm")

(define tn test-name)
(define *test-track-progress* #f)

; invalid form
(assert-error "define invalid form #1"
	      (lambda ()
		(define)))
(assert-error "define invalid form #2"
	      (lambda ()
		(define a)))
(assert-error "define invalid form #3"
	      (lambda ()
		(define 1 1)))
(assert-error "define invalid form #4"
	      (lambda ()
		(define a 1 'excessive)))
(assert-error "define invalid form #5"
	      (lambda ()
		(define a . 2)))
(if (and (provided? "sigscheme")
         (provided? "strict-argcheck"))
    (assert-error "define invalid form #6"
                  (lambda ()
                    (define (f x) . x))))

; basic define
(define val1 3)
(assert-equal? "basic define check" 3 val1)

; redefine
(define val1 5)
(assert-equal? "redefine check" 5 val1)

; define lambda
(define (what? x)
  "DEADBEEF" x)
(assert-equal? "func define" 10 (what? 10))

(define what2?
  (lambda (x)
    "DEADBEEF" x))
(assert-equal? "func define" 10 (what2? 10))

(define (nullarg)
  "nullarg")
(assert-equal? "nullarg test" "nullarg" (nullarg))

(define (add x y)
  (+ x y))
(assert-equal? "func define" 10 (add 2 8))

; tests for dot list arguments
(define (dotarg1 . a)
  a)
(assert-equal? "dot arg test 1" '(1 2) (dotarg1 1 2))

(define (dotarg2 a . b)
  a)
(assert-equal? "dot arg test 2" 1 (dotarg2 1 2))

(define (dotarg3 a . b)
  b)
(assert-equal? "dot arg test 3" '(2) (dotarg3 1 2))
(assert-equal? "dot arg test 4" '(2 3) (dotarg3 1 2 3))


(define (dotarg4 a b . c)
  b)
(assert-equal? "dot arg test 5" 2 (dotarg4 1 2 3))

(define (dotarg5 a b . c)
  c)
(assert-equal? "dot arg test 6" '(3 4) (dotarg5 1 2 3 4))

; test for internal define
(define (idefine-o a)
  (define (idefine-i c)
    (+ c 3))
  (idefine-i a))

(assert-equal? "internal define1" 5 (idefine-o 2))

(define (idefine0 a)
  (define (idefine1 . args)
    (apply +  args))
  (define (idefine2 c)
    (+ c 2))
  (+ (idefine1 1 2 3 4 5) (idefine2 a)))

(assert-equal? "internal define2" 17 (idefine0 0))

(if (or (symbol-bound? 'f)
        (symbol-bound? 'x)
        (symbol-bound? 'y)
        (symbol-bound? 'foo)
        (symbol-bound? 'bar))
    (error "global variables for internal definitions tests are tainted"))

(tn "internal defintions")
(assert-equal? (tn)
               14
               (let ((x 5))
                 (+ (let ()
                      (define x 6)
                      (+ x 3))
                    x)))
(assert-equal? (tn)
               14
               (let ((x 5))
                 (+ (let* ()
                      (define x 6)
                      (+ x 3))
                    x)))
(assert-equal? (tn)
               14
               (let ((x 5))
                 (+ (letrec ()
                      (define x 6)
                      (+ x 3))
                    x)))
(assert-equal? (tn)
               14
               (let ((x 5))
                 (+ ((lambda ()
                       (define x 6)
                       (+ x 3)))
                    x)))
(assert-equal? (tn)
               14
               (let ((x 5))
                 (+ (let ()
                      (define (f)
                        (define x 6)
                        (+ x 3))
                      (f))
                    x)))

(tn "internal defintions: letrec-like behavior")
(assert-equal? (tn)
               45
               (let ((x 5))
                 (define foo (lambda (y) (bar x y)))
                 (define bar (lambda (a b) (+ (* a b) a)))
                 (foo (+ x 3))))
(assert-equal? (tn)
               45
               (let ((x 5))
                 (define bar (lambda (a b) (+ (* a b) a)))
                 (define foo (lambda (y) (bar x y)))
                 (foo (+ x 3))))
(assert-error (tn)
               (lambda ()
                 (let ((x 5))
                   (define foo bar)
                   (define bar (lambda (a b) (+ (* a b) a)))
                   (foo x (+ x 3)))))
(assert-error  (tn)
               (lambda ()
                 (let ((x 5))
                   (define bar (lambda (a b) (+ (* a b) a)))
                   (define foo bar)
                   (foo x (+ x 3)))))
(assert-error  (tn)
               (lambda ()
                 (let ()
                   (define foo 1)
                   (define bar (+ foo 1))
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 (let ()
                   (define bar (+ foo 1))
                   (define foo 1)
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 (let ((foo 3))
                   (define foo 1)
                   (define bar (+ foo 1))
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 (let ((foo 3))
                   (define bar (+ foo 1))
                   (define foo 1)
                   (+ foo bar))))

(tn "internal defintions: non-beginning of block")
(assert-error  (tn)
               (lambda ()
                 (let ()
                   (define foo 1)
                   (set! foo 5)
                   (define bar 2)
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 (let* ()
                   (define foo 1)
                   (set! foo 5)
                   (define bar 2)
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 (letrec ()
                   (define foo 1)
                   (set! foo 5)
                   (define bar 2)
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 ((lambda ()
                    (define foo 1)
                    (set! foo 5)
                    (define bar 2)
                    (+ foo bar)))))
(assert-error  (tn)
               (lambda ()
                 (define (f)
                   (define foo 1)
                   (set! foo 5)
                   (define bar 2)
                   (+ foo bar))
                 (f)))

(tn "internal defintions: non-beginning of block (in begin)")
(assert-error  (tn)
               (lambda ()
                 (let ()
                   (define foo 1)
                   (set! foo 5)
                   (begin
                     (define bar 2))
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 (let* ()
                   (define foo 1)
                   (set! foo 5)
                   (begin
                     (define bar 2))
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 (letrec ()
                   (define foo 1)
                   (set! foo 5)
                   (begin
                     (define bar 2))
                   (+ foo bar))))
(assert-error  (tn)
               (lambda ()
                 ((lambda ()
                    (define foo 1)
                    (set! foo 5)
                    (begin
                      (define bar 2))
                    (+ foo bar)))))
(assert-error  (tn)
               (lambda ()
                 (define (f)
                   (define foo 1)
                   (set! foo 5)
                   (begin
                     (define bar 2))
                   (+ foo bar))
                 (f)))

(tn "internal defintions: non-beginning of block (in eval)")
(assert-equal? (tn)
               7
               (let ()
                 (define foo 1)
                 (set! foo 5)
                 (eval '(define bar 2)
                       (interaction-environment))
                 (+ foo bar)))
(assert-equal? (tn)
               7
               (let* ()
                 (define foo 1)
                 (set! foo 5)
                 (eval '(define bar 2)
                       (interaction-environment))
                 (+ foo bar)))
(assert-equal? (tn)
               7
               (letrec ()
                 (define foo 1)
                 (set! foo 5)
                 (eval '(define bar 2)
                       (interaction-environment))
                 (+ foo bar)))
(assert-equal? (tn)
               7
               ((lambda ()
                  (define foo 1)
                  (set! foo 5)
                  (eval '(define bar 2)
                        (interaction-environment))
                  (+ foo bar))))
(assert-equal? (tn)
               7
               (let ()
                 (define (f)
                   (define foo 1)
                   (set! foo 5)
                   (eval '(define bar 2)
                         (interaction-environment))
                   (+ foo bar))
                 (f)))

;; As specified as follows in R5RS, definitions in following forms are invalid.
;;
;; 5.2 Definitions
;;
;; Definitions are valid in some, but not all, contexts where expressions are
;; allowed. They are valid only at the top level of a <program> and at the
;; beginning of a <body>.
;;
;; 5.2.2 Internal definitions
;;
;; Definitions may occur at the beginning of a <body> (that is, the body of a
;; lambda, let, let*, letrec, let-syntax, or letrec-syntax expression or that
;; of a definition of an appropriate form).
;;
;; Wherever an internal definition may occur (begin <definition1> ...) is
;; equivalent to the sequence of definitions that form the body of the begin.
(tn "definition in do")
(assert-error (tn)
              (lambda ()
                (do ((i 0 (+ i 1)))
                    ((= i 1) (+ x 3))
                  (define x 6))))
(assert-error (tn)
              (lambda ()
                (do ((i 0 (+ i 1)))
                    ((= i 1) (+ x 3))
                  (begin
                    (define x 6)))))
(assert-equal? (tn)
               9
               (do ((i 0 (+ i 1)))
                   ((= i 1) (+ x 3))
                 (eval '(define x 6)
                       (interaction-environment))))
(tn "definition in if")
(assert-error  (tn)
               (lambda ()
                 (if #t
                     (define x 6))))
(assert-error  (tn)
               (lambda ()
                 (if #t
                     (begin
                       (define x 6)))))
(assert-equal? (tn)
               'x
               (if #t
                   (eval '(define x 6)
                         (interaction-environment))))

;; 'begin' is treated as if transparent, as described as the third rule of
;; above.
(tn "definition in begin")
(assert-equal? (tn)
               3
               (let ()
                 (begin
                   (define foo 1)
                   (define bar 2)
                   (+ foo bar))))
(assert-equal? (tn)
               3
               (let* ()
                 (begin
                   (define foo 1)
                   (define bar 2)
                   (+ foo bar))))
(assert-equal? (tn)
               3
               (letrec ()
                 (begin
                   (define foo 1)
                   (define bar 2)
                   (+ foo bar))))
(assert-equal? (tn)
               3
               ((lambda ()
                  (begin
                    (define foo 1)
                    (define bar 2)
                    (+ foo bar)))))
(assert-equal? (tn)
               3
               (let ()
                 (define (f)
                   (begin
                     (define foo 1)
                     (define bar 2)
                     (+ foo bar)))
                 (f)))
(tn "definition in sequencial begin")
(assert-equal? (tn)
               3
               (let ()
                 (begin
                   (define foo 4)
                   (define bar 5))
                 (begin
                   (define foo 1)
                   (define bar 2)
                   (+ foo bar))))
(assert-equal? (tn)
               3
               (let* ()
                 (begin
                   (define foo 4)
                   (define bar 5))
                 (begin
                   (define foo 1)
                   (define bar 2)
                   (+ foo bar))))
(assert-equal? (tn)
               3
               (letrec ()
                 (begin
                   (define foo 4)
                   (define bar 5))
                 (begin
                   (define foo 1)
                   (define bar 2)
                   (+ foo bar))))
(assert-equal? (tn)
               3
               ((lambda ()
                  (begin
                    (define foo 4)
                    (define bar 5))
                  (begin
                    (define foo 1)
                    (define bar 2)
                    (+ foo bar)))))
(assert-equal? (tn)
               3
               (let ()
                 (define (f)
                   (begin
                     (define foo 4)
                     (define bar 5))
                   (begin
                     (define foo 1)
                     (define bar 2)
                     (+ foo bar)))
                 (f)))
(tn "definition in sequencial nested begin")
(assert-equal? (tn)
               3
               (let ()
                 (begin
                   (define foo 4)
                   (define bar 5))
                 (begin
                   (define foo 6)
                   (begin
                     (define foo 1)
                     (define bar 2))
                   (+ foo bar))))
(assert-equal? (tn)
               3
               (let* ()
                 (begin
                   (define foo 4)
                   (define bar 5))
                 (begin
                   (define foo 6)
                   (begin
                     (define foo 1)
                     (define bar 2))
                   (+ foo bar))))
(assert-equal? (tn)
               3
               (letrec ()
                 (begin
                   (define foo 4)
                   (define bar 5))
                 (begin
                   (define foo 6)
                   (begin
                     (define foo 1)
                     (define bar 2))
                   (+ foo bar))))
(assert-equal? (tn)
               3
               ((lambda ()
                  (begin
                    (define foo 4)
                    (define bar 5))
                  (begin
                    (define foo 1)
                    (define bar 2)
                    (+ foo bar)))))
(assert-equal? (tn)
               3
               (let ()
                 (define (f)
                   (begin
                     (define foo 4)
                     (define bar 5))
                   (begin
                     (define foo 6)
                     (begin
                       (define foo 1)
                       (define bar 2))
                     (+ foo bar)))
                 (f)))
(tn "definition in invalid sequencial begin")
(assert-error  (tn)
               (lambda ()
                 (let ()
                   (begin
                     (define foo 4)
                     (define bar 5)
                     (set! foo 3))
                   (begin
                     (define foo 1)
                     (define bar 2)
                     (+ foo bar)))))
(assert-error  (tn)
               (lambda ()
                 (let* ()
                   (begin
                     (define foo 4)
                     (define bar 5)
                     (set! foo 3))
                   (begin
                     (define foo 1)
                     (define bar 2)
                     (+ foo bar)))))
(assert-error  (tn)
               (lambda ()
                 (letrec ()
                   (begin
                     (define foo 4)
                     (define bar 5)
                     (set! foo 3))
                   (begin
                     (define foo 1)
                     (define bar 2)
                     (+ foo bar)))))
(assert-error  (tn)
               (lambda ()
                 ((lambda ()
                    (begin
                      (define foo 4)
                      (define bar 5)
                      (set! foo 3))
                    (begin
                      (define foo 1)
                      (define bar 2)
                      (+ foo bar))))))
(assert-error  (tn)
               (lambda ()
                 (let ()
                   (define (f)
                     (begin
                       (define foo 4)
                       (define bar 5)
                       (set! foo 3))
                     (begin
                       (define foo 1)
                       (define bar 2)
                       (+ foo bar)))
                   (f))))

; set!
(define (set-dot a . b)
  (set! b '(1 2))
  b)

(assert-equal? "set dot test" '(1 2) (set-dot '()))

(if (and (provided? "sigscheme")
         (provided? "strict-argcheck"))
    (begin
      (tn "define function form: boolean as an arg")
      (assert-error (tn) (lambda () (define (f . #t) #t)))
      (assert-error (tn) (lambda () (define (f #t) #t)))
      (assert-error (tn) (lambda () (define (f x #t) #t)))
      (assert-error (tn) (lambda () (define (f #t x) #t)))
      (assert-error (tn) (lambda () (define (f x . #t) #t)))
      (assert-error (tn) (lambda () (define (f #t . x) #t)))
      (assert-error (tn) (lambda () (define (f x y #t) #t)))
      (assert-error (tn) (lambda () (define (f x y . #t) #t)))
      (assert-error (tn) (lambda () (define (f x #t y) #t)))
      (assert-error (tn) (lambda () (define (f x #t . y) #t)))
      (tn "define function form: intger as an arg")
      (assert-error (tn) (lambda () (define (f . 1) #t)))
      (assert-error (tn) (lambda () (define (f 1) #t)))
      (assert-error (tn) (lambda () (define (f x 1) #t)))
      (assert-error (tn) (lambda () (define (f 1 x) #t)))
      (assert-error (tn) (lambda () (define (f x . 1) #t)))
      (assert-error (tn) (lambda () (define (f 1 . x) #t)))
      (assert-error (tn) (lambda () (define (f x y 1) #t)))
      (assert-error (tn) (lambda () (define (f x y . 1) #t)))
      (assert-error (tn) (lambda () (define (f x 1 y) #t)))
      (assert-error (tn) (lambda () (define (f x 1 . y) #t)))
      (tn "define function form: null as an arg")
      (assert-true  (tn)            (define (f . ()) #t))
      (assert-error (tn) (lambda () (define (f ()) #t)))
      (assert-error (tn) (lambda () (define (f x ()) #t)))
      (assert-error (tn) (lambda () (define (f () x) #t)))
      (assert-true  (tn)            (define (f x . ()) #t))
      (assert-error (tn) (lambda () (define (f () . x) #t)))
      (assert-error (tn) (lambda () (define (f x y ()) #t)))
      (assert-true  (tn)            (define (f x y . ()) #t))
      (assert-error (tn) (lambda () (define (f x () y) #t)))
      (assert-error (tn) (lambda () (define (f x () . y) #t)))
      (tn "define function form: pair as an arg")
      (assert-true  (tn)            (define (f . (a)) #t))
      (assert-error (tn) (lambda () (define (f (a)) #t)))
      (assert-error (tn) (lambda () (define (f x (a)) #t)))
      (assert-error (tn) (lambda () (define (f (a) x) #t)))
      (assert-true  (tn)            (define (f x . (a)) #t))
      (assert-error (tn) (lambda () (define (f (a) . x) #t)))
      (assert-error (tn) (lambda () (define (f x y (a)) #t)))
      (assert-true  (tn)            (define (f x y . (a)) #t))
      (assert-error (tn) (lambda () (define (f x (a) y) #t)))
      (assert-error (tn) (lambda () (define (f x (a) . y) #t)))
      (tn "define function form: char as an arg")
      (assert-error (tn) (lambda () (define (f . #\a) #t)))
      (assert-error (tn) (lambda () (define (f #\a) #t)))
      (assert-error (tn) (lambda () (define (f x #\a) #t)))
      (assert-error (tn) (lambda () (define (f #\a x) #t)))
      (assert-error (tn) (lambda () (define (f x . #\a) #t)))
      (assert-error (tn) (lambda () (define (f #\a . x) #t)))
      (assert-error (tn) (lambda () (define (f x y #\a) #t)))
      (assert-error (tn) (lambda () (define (f x y . #\a) #t)))
      (assert-error (tn) (lambda () (define (f x #\a y) #t)))
      (assert-error (tn) (lambda () (define (f x #\a . y) #t)))
      (tn "define function form: string as an arg")
      (assert-error (tn) (lambda () (define (f . "a") #t)))
      (assert-error (tn) (lambda () (define (f "a") #t)))
      (assert-error (tn) (lambda () (define (f x "a") #t)))
      (assert-error (tn) (lambda () (define (f "a" x) #t)))
      (assert-error (tn) (lambda () (define (f x . "a") #t)))
      (assert-error (tn) (lambda () (define (f "a" . x) #t)))
      (assert-error (tn) (lambda () (define (f x y "a") #t)))
      (assert-error (tn) (lambda () (define (f x y . "a") #t)))
      (assert-error (tn) (lambda () (define (f x "a" y) #t)))
      (assert-error (tn) (lambda () (define (f x "a" . y) #t)))
      (tn "define function form: vector as an arg")
      (assert-error (tn) (lambda () (define (f . #(a)) #t)))
      (assert-error (tn) (lambda () (define (f #(a)) #t)))
      (assert-error (tn) (lambda () (define (f x #(a)) #t)))
      (assert-error (tn) (lambda () (define (f #(a) x) #t)))
      (assert-error (tn) (lambda () (define (f x . #(a)) #t)))
      (assert-error (tn) (lambda () (define (f #(a) . x) #t)))
      (assert-error (tn) (lambda () (define (f x y #(a)) #t)))
      (assert-error (tn) (lambda () (define (f x y . #(a)) #t)))
      (assert-error (tn) (lambda () (define (f x #(a) y) #t)))
      (assert-error (tn) (lambda () (define (f x #(a) . y) #t)))))

(total-report)