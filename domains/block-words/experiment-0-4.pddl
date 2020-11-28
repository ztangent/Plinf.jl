(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear r)
		(on r o)
		(on o w)
		(ontable w)

		(clear c)
		(on c e)
		(ontable e)

		(ontable p)
		(clear p)
	)
	(:goal (and
		;; cower
		(clear c) (ontable r) (on c o) (on o w) (on w e) (on e r)
	))
)
