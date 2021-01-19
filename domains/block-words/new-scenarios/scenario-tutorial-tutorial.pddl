(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear p)
		(ontable p)

		(clear r)
		(ontable r)

		(clear e)
		(on e o)
		(ontable o)

		(clear w)
		(on w c)
		(ontable c)


	)
	(:goal (and
		;; power
		(clear p) (ontable r) (on e r) (on w e) (on o w) (on p o)
	))
)
