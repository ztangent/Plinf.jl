(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear o)
		(on o c)
		(ontable c)

		(clear e)
		(on e p)
		(on p w)
		(ontable w)

		(clear r)
		(ontable r)
	)
	(:goal (and
		;; cower
		(clear c) (ontable r) (on c o) (on o w) (on w e) (on e r)
	))
)
