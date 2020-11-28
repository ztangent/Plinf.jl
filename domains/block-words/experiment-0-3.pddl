(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear p)
		(ontable p)

		(clear a)
		(on a w)
		(ontable w)

		(clear r)
		(on r e)
		(on e d)
		(ontable d)
	)
	(:goal (and
		;; war
		(clear w) (ontable r) (on a r) (on w a)
	))
)
