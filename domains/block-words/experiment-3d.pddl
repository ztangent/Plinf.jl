(define (problem block_words)
	(:domain block-words)
	(:objects
		c r o w e a d p - block
	)
	(:init
		(handempty)

		(clear c)
		(on c w)
		(on w o)
		(ontable o)

		(clear a)
		(on a d)
		(on d e)
		(ontable e)

		(clear p)
		(on p r)
		(ontable r)
	)
	(:goal (and
		;; crow
		(clear c) (ontable w) (on c r) (on r o) (on o w)
	))
)
