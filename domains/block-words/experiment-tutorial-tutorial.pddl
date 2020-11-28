(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear e)
		(on e w)
		(ontable w)

		(clear o)
		(on o p)
		(on p c)
		(ontable c)

		(clear r)
		(ontable r)

	)
	(:goal (and
		;; power
		(clear p) (ontable r) (on e r) (on w e) (on o w) (on p o)
	))
)
