(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear c)
		(on c e)
		(ontable e)

		(clear o)
		(on o p)
		(ontable p)

		(clear r)
		(ontable r)

		(clear w)
		(ontable w)
	)
	(:goal (and
		;; core
		(clear c) (ontable e) (on r e) (on o r) (on c o)
	))
)
