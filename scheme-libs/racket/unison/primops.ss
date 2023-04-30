; This library implements pimitive operations that are used in
; builtins. There are two different sorts of primitive operations, but
; the difference is essentially irrelevant except for naming schemes.
;
; POps are part of a large enumeration of 'instructions' directly
; implemented in the Haskell runtime. These are referred to using the
; naming scheme `unison-POp-INST` where `INST` is the name of the
; instruction, which is (at the time of this writing) 4 letters.
;
; FOps are 'foreign' functons, which are allowed to be declared more
; flexibly in the Haskell runtime. Each such declaration associates a
; builtin to a Haskell function. For these, the naming shceme is
; `unison-FOp-NAME` where `NAME` is the name of the unison builtin
; associated to the declaration.
;
; Both POps and FOps are always called with exactly the right number
; of arguments, so they may be implemented as ordinary scheme
; definitions with a fixed number of arguments. By implementing the
; POp/FOp, you are expecting the associated unison function(s) to be
; implemented by code generation from the wrappers in
; Unison.Runtime.Builtin, so the POp/FOp implementation must
; take/return arguments that match what is expected in those wrappers.

#!r6rs
(library (unison primops)
  (export
    ; unison-FOp-Bytes.decodeNat16be
    ; unison-FOp-Bytes.decodeNat32be
    ; unison-FOp-Bytes.decodeNat64be
    unison-FOp-Char.toText
    ; unison-FOp-Code.dependencies
    ; unison-FOp-Code.serialize
    unison-FOp-IO.closeFile.impl.v3
    unison-FOp-IO.openFile.impl.v3
    unison-FOp-IO.putBytes.impl.v3
    unison-FOp-Text.fromUtf8.impl.v3
    unison-FOp-Text.repeat
    unison-FOp-Text.reverse
    unison-FOp-Text.toUtf8
    unison-FOp-Text.toLowercase
    unison-FOp-Text.toUppercase
    unison-FOp-Pattern.run
    unison-FOp-Pattern.isMatch
    unison-FOp-Pattern.many
    unison-FOp-Pattern.capture
    unison-FOp-Pattern.join
    unison-FOp-Pattern.or
    unison-FOp-Pattern.replicate
    unison-FOp-Text.patterns.digit
    unison-FOp-Text.patterns.letter
    unison-FOp-Text.patterns.punctuation
    unison-FOp-Text.patterns.charIn
    unison-FOp-Text.patterns.notCharIn
    unison-FOp-Text.patterns.anyChar
    unison-FOp-Text.patterns.space
    unison-FOp-Text.patterns.charRange
    unison-FOp-Text.patterns.notCharRange
    unison-FOp-Text.patterns.literal
    unison-FOp-Text.patterns.eof
    unison-FOp-Text.patterns.char
    unison-FOp-Char.Class.is
    unison-FOp-Char.Class.any
    unison-FOp-Char.Class.alphanumeric
    unison-FOp-Char.Class.upper
    unison-FOp-Char.Class.lower
    unison-FOp-Char.Class.number
    unison-FOp-Char.Class.punctuation
    unison-FOp-Char.Class.symbol
    unison-FOp-Char.Class.letter
    unison-FOp-Char.Class.whitespace
    unison-FOp-Char.Class.control
    unison-FOp-Char.Class.printable
    unison-FOp-Char.Class.mark
    unison-FOp-Char.Class.separator
    unison-FOp-Char.Class.or
    unison-FOp-Char.Class.range
    unison-FOp-Char.Class.anyOf
    unison-FOp-Char.Class.and
    unison-FOp-Char.Class.not


    ; unison-FOp-Value.serialize
    unison-FOp-IO.stdHandle
    unison-FOp-IO.getArgs.impl.v1

    unison-FOp-ImmutableArray.copyTo!
    unison-FOp-ImmutableArray.read

    unison-FOp-MutableArray.freeze!
    unison-FOp-MutableArray.freeze
    unison-FOp-MutableArray.read
    unison-FOp-MutableArray.write

    unison-FOp-MutableArray.size
    unison-FOp-ImmutableArray.size

    unison-FOp-MutableByteArray.size
    unison-FOp-ImmutableByteArray.size

    unison-FOp-MutableByteArray.length
    unison-FOp-ImmutableByteArray.length

    unison-FOp-ImmutableByteArray.copyTo!
    unison-FOp-ImmutableByteArray.read8

    unison-FOp-MutableByteArray.freeze!
    unison-FOp-MutableByteArray.write8

    unison-FOp-Scope.bytearray
    unison-FOp-Scope.bytearrayOf
    unison-FOp-Scope.array
    unison-FOp-Scope.arrayOf
    unison-FOp-Scope.ref

    unison-FOp-IO.bytearray
    unison-FOp-IO.bytearrayOf
    unison-FOp-IO.array
    unison-FOp-IO.arrayOf

    unison-FOp-IO.ref
    unison-FOp-Ref.read
    unison-FOp-Ref.write
    unison-FOp-Ref.readForCas
    unison-FOp-Ref.Ticket.read
    unison-FOp-Ref.cas

    unison-FOp-Promise.new
    unison-FOp-Promise.read
    unison-FOp-Promise.tryRead
    unison-FOp-Promise.write

    unison-FOp-IO.delay.impl.v3
    unison-POp-FORK
    unison-FOp-IO.kill.impl.v3
    unison-POp-TFRC

    unison-FOp-Handle.toText
    unison-FOp-Socket.toText
    unison-FOp-ThreadId.toText

    unison-POp-ADDN
    unison-POp-ANDN
    unison-POp-BLDS
    unison-POp-CATS
    unison-POp-CATT
    unison-POp-CATB
    unison-POp-CMPU
    unison-POp-COMN
    unison-POp-CONS
    unison-POp-DBTX
    unison-POp-DECI
    unison-POp-DIVN
    unison-POp-DRPB
    unison-POp-DRPS
    unison-POp-DRPT
    unison-POp-EQLN
    unison-POp-EQLT
    unison-POp-LEQT
    unison-POp-EQLU
    unison-POp-EROR
    unison-POp-FTOT
    unison-POp-IDXB
    unison-POp-IDXS
    unison-POp-IORN
    unison-POp-ITOT
    unison-POp-LEQN
    ; unison-POp-LKUP
    unison-POp-LZRO
    unison-POp-MULN
    unison-POp-MODN
    unison-POp-NTOT
    unison-POp-PAKT
    unison-POp-SHLI
    unison-POp-SHLN
    unison-POp-SHRI
    unison-POp-SHRN
    unison-POp-SIZS
    unison-POp-SIZT
    unison-POp-SIZB
    unison-POp-SNOC
    unison-POp-SUBN
    unison-POp-TAKS
    unison-POp-TAKT
    unison-POp-TAKB
    unison-POp-TRCE
    unison-POp-PRNT
    unison-POp-TTON
    unison-POp-TTOI
    unison-POp-TTOF
    unison-POp-UPKT
    unison-POp-XORN
    unison-POp-VALU
    unison-POp-VWLS
    unison-POp-UCNS
    unison-POp-USNC
    unison-POp-FLTB

    unison-POp-UPKB
    unison-POp-PAKB
    unison-POp-ADDI
    unison-POp-DIVI
    unison-POp-EQLI
    unison-POp-MODI
    unison-POp-LEQI
    unison-POp-POWN
    unison-POp-VWRS
    unison-POp-SPLL
    unison-POp-SPLR

    unison-FOp-crypto.hashBytes
    unison-FOp-crypto.hmacBytes
    unison-FOp-crypto.HashAlgorithm.Md5
    unison-FOp-crypto.HashAlgorithm.Sha1
    unison-FOp-crypto.HashAlgorithm.Sha2_256
    unison-FOp-crypto.HashAlgorithm.Sha2_512
    unison-FOp-crypto.HashAlgorithm.Sha3_256
    unison-FOp-crypto.HashAlgorithm.Sha3_512
    unison-FOp-crypto.HashAlgorithm.Blake2s_256
    unison-FOp-crypto.HashAlgorithm.Blake2b_256
    unison-FOp-crypto.HashAlgorithm.Blake2b_512

    unison-FOp-IO.clientSocket.impl.v3
    unison-FOp-IO.closeSocket.impl.v3
    unison-FOp-IO.socketReceive.impl.v3
    unison-FOp-IO.socketSend.impl.v3
    unison-FOp-IO.socketPort.impl.v3
    unison-FOp-IO.serverSocket.impl.v3
    unison-FOp-IO.socketAccept.impl.v3
    unison-FOp-IO.listen.impl.v3
    unison-FOp-Tls.ClientConfig.default
    unison-FOp-Tls.ClientConfig.certificates.set
    unison-FOp-Tls.decodeCert.impl.v3
    unison-FOp-Tls.newServer.impl.v3
    unison-FOp-Tls.decodePrivateKey
    unison-FOp-Tls.ServerConfig.default
    unison-FOp-Tls.handshake.impl.v3
    unison-FOp-Tls.newClient.impl.v3
    unison-FOp-Tls.receive.impl.v3
    unison-FOp-Tls.send.impl.v3
    unison-FOp-Tls.terminate.impl.v3)

  (import (rnrs)
          (only (srfi :13) string-reverse)
          (rename
           (only (racket base)
                 car
                 cdr
                 foldl
                 bytes->string/utf-8
                 string->bytes/utf-8
                 exn:fail:contract?
                 with-handlers)
           (car icar) (cdr icdr))
          (unison core)
          (unison data)
          (unison chunked-seq)
          (unison pattern)
          (unison crypto)
          (unison data)
          (unison tls)
          (unison tcp)
          (unison concurrent))

  (define (unison-POp-UPKB bs)
    (build-chunked-list
     (chunked-bytes-length bs)
     (lambda (i) (chunked-bytes-ref bs i))))

  (define unison-POp-ADDI +)
  (define unison-POp-DIVI /)
  (define (unison-POp-EQLI a b)
    (if (= a b) 1 0))
  (define unison-POp-MODI mod)
  (define unison-POp-LEQI <=)
  (define unison-POp-POWN expt)

  (define (reify-exn thunk)
    (guard
      (e [else
           (sum 0 '() (exception->string e) e)])
      (thunk)))

  ; Core implemented primops, upon which primops-in-unison can be built.
  (define (unison-POp-ADDN m n) (fx+ m n))
  (define (unison-POp-ANDN m n) (fxand m n))
  (define unison-POp-BLDS
    (lambda args-list
      (fold-right (lambda (e l) (chunked-list-add-first l e)) empty-chunked-list args-list)))
  (define (unison-POp-CATS l r) (chunked-list-append l r))
  (define (unison-POp-CATT l r) (chunked-string-append l r))
  (define (unison-POp-CATB l r) (chunked-bytes-append l r))
  (define (unison-POp-CMPU l r) (ord (universal-compare l r)))
  (define (unison-POp-COMN n) (fxnot n))
  (define (unison-POp-CONS x xs) (chunked-list-add-first xs x))
  (define (unison-POp-DECI n) (fx1- n))
  (define (unison-POp-DIVN m n) (fxdiv m n))
  (define (unison-POp-DRPB n bs) (chunked-bytes-drop bs n))
  (define (unison-POp-DRPS n l) (chunked-list-drop l n))
  (define (unison-POp-DRPT n t) (chunked-string-drop t n))
  (define (unison-POp-EQLN m n) (bool (fx=? m n)))
  (define (unison-POp-EQLT s t) (bool (equal? s t)))
  (define (unison-POp-LEQT s t) (bool (chunked-string<? s t)))
  (define (unison-POp-EQLU x y) (bool (universal=? x y)))
  (define (unison-POp-EROR fnm x) ;; TODO raise the correct failure, use display
    (let-values ([(p g) (open-string-output-port)])
      (put-string p (chunked-string->string fnm))
      (put-string p ": ")
      (display (describe-value x) p)
      (raise (make-exn:bug fnm x))))
  (define (unison-POp-FTOT f) (string->chunked-string (number->string f)))
  (define (unison-POp-IDXB n bs)
    (guard (x [else none])
      (some (chunked-bytes-ref bs n))))
  (define (unison-POp-IDXS n l)
    (guard (x [else none])
      (some (chunked-list-ref l n))))
  (define (unison-POp-IORN m n) (fxior m n))
  (define (unison-POp-ITOT n)
    (string->chunked-string (number->string n)))
  (define (unison-POp-LEQN m n) (bool (fx<=? m n)))
  (define (unison-POp-LZRO m) (- 64 (fxlength m)))
  (define (unison-POp-MULN m n) (fx* m n))
  (define (unison-POp-MODN m n) (fxmod m n))
  (define (unison-POp-NTOT n) (string->chunked-string (number->string n)))
  (define (unison-POp-PAKB l)
    (build-chunked-bytes
     (chunked-list-length l)
     (lambda (i) (chunked-list-ref l i))))
  (define (unison-POp-PAKT l)
    (build-chunked-string
     (chunked-list-length l)
     (lambda (i) (chunked-list-ref l i))))
  (define (unison-POp-SHLI i k) (fxarithmetic-shift-left i k))
  (define (unison-POp-SHLN n k) (fxarithmetic-shift-left n k))
  (define (unison-POp-SHRI i k) (fxarithmetic-shift-right i k))
  (define (unison-POp-SHRN n k) (fxarithmetic-shift-right n k))
  (define (unison-POp-SIZS l) (chunked-list-length l))
  (define (unison-POp-SIZT t) (chunked-string-length t))
  (define (unison-POp-SIZB b) (chunked-bytes-length b))
  (define (unison-POp-SNOC xs x) (chunked-list-add-last xs x))
  (define (unison-POp-SUBN m n) (fx- m n))
  (define (unison-POp-TAKS n s) (chunked-list-take s n))
  (define (unison-POp-TAKT n t) (chunked-string-take t n))
  (define (unison-POp-TAKB n t) (chunked-bytes-take t n))

  ;; TODO currently only runs in low-level tracing support
  (define (unison-POp-DBTX x)
    (sum 1 (string->chunked-string (describe-value x))))

  (define (unison-FOp-Handle.toText h)
    (string->chunked-string (describe-value h)))
  (define (unison-FOp-Socket.toText s)
    (string->chunked-string (describe-value s)))
  (define (unison-FOp-ThreadId.toText tid)
    (string->chunked-string (describe-value tid)))

  (define (unison-POp-TRCE s x)
    (display "trace: ")
    (display (chunked-string->string s))
    (newline)
    (display (describe-value x))
    (newline))
  (define (unison-POp-PRNT s)
    (display (chunked-string->string s))
    (newline))
  (define (unison-POp-TTON s)
    (let ([mn (string->number (chunked-string->string s))])
      (if (and (fixnum? mn) (>= mn 0)) (some mn) none)))
  (define (unison-POp-TTOI s)
    (let ([mn (string->number (chunked-string->string s))])
      (if (fixnum? mn) (some mn) none)))
  (define (unison-POp-TTOF s)
    (let ([mn (string->number (chunked-string->string s))])
      (if mn (some mn) none)))
  (define (unison-POp-UPKT s)
    (build-chunked-list
     (chunked-string-length s)
     (lambda (i) (chunked-string-ref s i))))
  (define (unison-POp-VWLS l)
    (if (chunked-list-empty? l)
        (sum 0)
        (let-values ([(t h) (chunked-list-pop-first l)])
          (sum 1 h t))))
  (define (unison-POp-VWRS l)
    (if (chunked-list-empty? l)
        (sum 0)
        (let-values ([(t h) (chunked-list-pop-last l)])
          (sum 1 t h))))
  (define (unison-POp-SPLL i s)
    (if (< (chunked-list-length s) i)
        (sum 0)
        (let-values ([(l r) (chunked-list-split-at s i)])
          (sum 1 l r))))
  (define (unison-POp-SPLR i s) ; TODO write test that stresses this
    (let ([len (chunked-list-length s) ])
      (if (< len i)
          (sum 0)
          (let-values ([(l r) (chunked-list-split-at s (- len i))])
            (sum 1 l r)))))

  (define (unison-POp-UCNS s)
    (if (chunked-string-empty? s)
        (sum 0)
        (let-values ([(t h) (chunked-string-pop-first s)])
          (sum 1 (char h) t))))

  (define (unison-POp-USNC s)
    (if (chunked-string-empty? s)
        (sum 0)
        (let-values ([(t h) (chunked-string-pop-last s)])
          (sum 1 t (char h)))))

  ;; TODO flatten operation on Bytes is a no-op for now (and possibly ever)
  (define (unison-POp-FLTB b) b)

  (define (unison-POp-XORN m n) (fxxor m n))
  (define (unison-POp-VALU c) (decode-value c))

  (define (unison-FOp-IO.putBytes.impl.v3 p bs)
    (begin
      (put-bytevector p (chunked-bytes->bytes bs))
      (flush-output-port p)
      (sum 1 #f)))

  (define (unison-FOp-Char.toText c) (string->chunked-string (string (integer->char c))))

  (define stdin (standard-input-port))
  (define stdout (standard-output-port))
  (define stderr (standard-error-port))

  (define (unison-FOp-IO.stdHandle n)
    (case n
      [(0) stdin]
      [(1) stdout]
      [(2) stderr]))

  (define (unison-FOp-IO.getArgs.impl.v1)
    (sum 1 (cdr (command-line))))

  ;; TODO should we convert Bytes -> Text directly without the intermediate conversions?
  (define (unison-FOp-Text.fromUtf8.impl.v3 b)
    (with-handlers
      ([exn:fail:contract? ; TODO proper typeLink
        (lambda (e) (exception "MiscFailure" (exception->string e) ()))])
      (right (string->chunked-string (bytes->string/utf-8 (chunked-bytes->bytes b))))))

  ;; TODO should we convert Text -> Bytes directly without the intermediate conversions?
  (define (unison-FOp-Text.toUtf8 s)
    (bytes->chunked-bytes (string->bytes/utf-8 (chunked-string->string s))))

  (define (unison-FOp-IO.closeFile.impl.v3 h)
    (close-input-port h))

  (define (unison-FOp-IO.openFile.impl.v3 fn mode)
    (case mode
      [(0) (open-file-input-port fn)]
      [(1) (open-file-output-port fn)]
      [(2) (open-file-output-port fn 'no-truncate)]
      [else (open-file-input/output-port fn)]))

  (define (unison-FOp-Text.repeat n t)
    (let loop ([cnt 0]
               [acc empty-chunked-string])
      (if (= cnt n)
          acc
          (loop (+ cnt 1) (chunked-string-append acc t)))))

  (define (unison-FOp-Text.reverse s)
    (chunked-string-foldMap-chunks
     s
     string-reverse
     (lambda (acc c) (chunked-string-append c acc))))

  (define (unison-FOp-Text.toLowercase s)
    (chunked-string-foldMap-chunks s string-downcase chunked-string-append))

  (define (unison-FOp-Text.toUppercase s)
    (chunked-string-foldMap-chunks s string-upcase chunked-string-append))

  (define (unison-FOp-Pattern.run p s)
    (let* ([r (pattern-match p s)])
      (if r (sum 1 (icdr r) (icar r)) (sum 0))))

  (define (unison-FOp-Pattern.isMatch p s) (bool (pattern-match? p s)))
  (define (unison-FOp-Pattern.many p) (many p))
  (define (unison-FOp-Pattern.capture p) (capture p))
  (define (unison-FOp-Pattern.join ps)
    (join* ps))
  (define (unison-FOp-Pattern.or p1 p2) (choice p1 p2))
  (define (unison-FOp-Pattern.replicate n m p) (replicate p n m))

  (define (unison-FOp-Text.patterns.digit) digit)
  (define (unison-FOp-Text.patterns.letter) letter)
  (define (unison-FOp-Text.patterns.punctuation) punctuation)
  (define (unison-FOp-Text.patterns.charIn cs) (chars cs))
  (define (unison-FOp-Text.patterns.notCharIn cs) (not-chars cs))
  (define (unison-FOp-Text.patterns.anyChar) any-char)
  (define (unison-FOp-Text.patterns.space) space)
  (define (unison-FOp-Text.patterns.charRange a z) (char-range (integer->char a) (integer->char z)))
  (define (unison-FOp-Text.patterns.notCharRange a z) (not-char-range (integer->char a) (integer->char z)))
  (define (unison-FOp-Text.patterns.literal s) (literal s))
  (define (unison-FOp-Text.patterns.eof) eof)
  (define (unison-FOp-Text.patterns.char cc) cc)
  (define (unison-FOp-Char.Class.is cc c)
    (unison-FOp-Pattern.isMatch cc (unison-FOp-Char.toText c)))
  (define (unison-FOp-Char.Class.any) (unison-FOp-Text.patterns.anyChar))
  (define (unison-FOp-Char.Class.punctuation)
    (unison-FOp-Text.patterns.punctuation))
  (define (unison-FOp-Char.Class.letter) (unison-FOp-Text.patterns.letter))
  (define (unison-FOp-Char.Class.alphanumeric) alphanumeric)
  (define (unison-FOp-Char.Class.upper) upper)
  (define (unison-FOp-Char.Class.lower) lower)
  (define (unison-FOp-Char.Class.number) number)
  (define (unison-FOp-Char.Class.symbol) symbol)
  (define (unison-FOp-Char.Class.whitespace) space)
  (define (unison-FOp-Char.Class.control) control)
  (define (unison-FOp-Char.Class.printable) printable)
  (define (unison-FOp-Char.Class.mark) mark)
  (define (unison-FOp-Char.Class.separator) separator)
  (define (unison-FOp-Char.Class.or p1 p2) (unison-FOp-Pattern.or p1 p2))
  (define (unison-FOp-Char.Class.range a z)
    (unison-FOp-Text.patterns.charRange a z))
  (define (unison-FOp-Char.Class.anyOf cs) (unison-FOp-Text.patterns.charIn cs))
  (define (unison-FOp-Char.Class.and cc1 cc2) (char-class-and cc1 cc2))
  (define (unison-FOp-Char.Class.not cc) (char-class-not cc))

  (define (catch-array thunk)
    (reify-exn thunk))

  (define (unison-FOp-ImmutableArray.read vec i)
    (catch-array
      (lambda ()
        (sum 1 (vector-ref vec i)))))

  (define (unison-FOp-ImmutableArray.copyTo! dst doff src soff n)
    (catch-array
      (lambda ()
        (let next ([i (fx1- n)])
          (if (< i 0)
            (sum 1 #f)
            (begin
              (vector-set! dst (+ doff i) (vector-ref src (+ soff i)))
              (next (fx1- i))))))))

  (define unison-FOp-MutableArray.freeze! freeze-vector!)

  (define unison-FOp-MutableArray.freeze freeze-subvector)

  (define (unison-FOp-MutableArray.read src i)
    (catch-array
      (lambda ()
        (sum 1 (vector-ref src i)))))

  (define (unison-FOp-MutableArray.write dst i x)
    (catch-array
      (lambda ()
        (vector-set! dst i x)
        (sum 1))))

  (define (unison-FOp-ImmutableByteArray.copyTo! dst doff src soff n)
    (catch-array
      (lambda ()
        (bytevector-copy! src soff dst doff n)
        (sum 1 #f))))

  (define (unison-FOp-ImmutableByteArray.read8 arr i)
    (catch-array
      (lambda ()
        (sum 1 (bytevector-u8-ref arr i)))))

  (define unison-FOp-MutableByteArray.freeze! freeze-bytevector!)

  (define (unison-FOp-MutableByteArray.write8 arr i b)
    (catch-array
      (lambda ()
        (bytevector-u8-set! arr i b)
        (sum 1))))

  (define (unison-FOp-Scope.bytearray n) (make-bytevector n))
  (define (unison-FOp-IO.bytearray n) (make-bytevector n))

  (define (unison-FOp-Scope.array n) (make-vector n))
  (define (unison-FOp-IO.array n) (make-vector n))

  (define (unison-FOp-Scope.bytearrayOf b n) (make-bytevector n b))
  (define (unison-FOp-IO.bytearrayOf b n) (make-bytevector n b))

  (define (unison-FOp-Scope.arrayOf v n) (make-vector n v))
  (define (unison-FOp-IO.arrayOf v n) (make-vector n v))

  (define unison-FOp-MutableByteArray.length bytevector-length)
  (define unison-FOp-ImmutableByteArray.length bytevector-length)
  (define unison-FOp-MutableByteArray.size bytevector-length)
  (define unison-FOp-ImmutableByteArray.size bytevector-length)
  (define unison-FOp-MutableArray.size vector-length)
  (define unison-FOp-ImmutableArray.size vector-length)

  (define (unison-POp-FORK thunk) (fork thunk))
  (define (unison-POp-TFRC thunk) (try-eval thunk))
  (define (unison-FOp-IO.delay.impl.v3 micros) (sleep micros))
  (define (unison-FOp-IO.kill.impl.v3 threadId) (kill threadId))
  (define (unison-FOp-Scope.ref a) (ref-new a))
  (define (unison-FOp-IO.ref a) (ref-new a))
  (define (unison-FOp-Ref.read ref) (ref-read ref))
  (define (unison-FOp-Ref.write ref a) (ref-write ref a))
  (define (unison-FOp-Ref.readForCas ref) (ref-read ref))
  (define (unison-FOp-Ref.Ticket.read ticket) ticket)
  (define (unison-FOp-Ref.cas ref ticket value) (ref-cas ref ticket value))
  (define (unison-FOp-Promise.new) (promise-new))
  (define (unison-FOp-Promise.read promise) (promise-read promise))
  (define (unison-FOp-Promise.tryRead promise) (promise-try-read promise))
  (define (unison-FOp-Promise.write promise a) (promise-write promise a)))