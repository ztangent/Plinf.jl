(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear r)
		(ontable r)

		(clear e)
		(on e w)
		(on w p)
		(ontable p)

		(clear c)
		(on c o)
		(ontable o)
	)
	(:goal (and
		;; power
		(clear p) (ontable r) (on p o) (on o w) (on w e) (on e r)
	))
)
