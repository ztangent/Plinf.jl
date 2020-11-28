(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear w)
		(ontable w)

		(clear p)
		(on p a)
		(on a r)
		(ontable r)

		(clear d)
		(on d e)
		(ontable e)

	)
	(:goal (and
		;; wade
		(clear w) (ontable e) (on d e) (on a d) (on w a)
	))
)
