(define (problem block_words)
	(:domain block-words)
	(:objects
		c r o w e a d p - block
	)
	(:init
		(handempty)

		(clear d)
		(on d c)
		(ontable c)

		(clear w)
		(on w r)
		(ontable r)

		(clear o)
		(ontable o)

		(clear a)
		(on a p)
		(on p e)
		(ontable e)
	)
	(:goal (and
		;; war
		(clear w) (ontable r) (on w a) (on a r)
	))
)
