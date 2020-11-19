(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear p)
		(on p r)
		(ontable r)

		(clear c)
		(on c e)
		(ontable e)

		(clear o)
		(ontable o)

		(clear w)
		(ontable w)

	)
	(:goal (and
		;; power
		(clear p) (ontable r) (on p o) (on o w) (on w e) (on e r)
	))
)
