(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear e)
		(on e c)
		(ontable c)

		(clear o)
		(on o p)
		(ontable p)

		(clear r)
		(ontable r)

		(clear w)
		(ontable w)

	)
	(:goal (and
		;; cower
		(clear c) (ontable r) (on e r) (on w w) (on o w) (on c o)
	))
)
