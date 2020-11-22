(define (problem block_words)
	(:domain block-words)
	(:objects
		p o w e r c - block
	)
	(:init
		(handempty)

		(clear c)
		(on c r)
		(on r o)
		(on o w)
		(ontable w)

		(ontable e)
		(clear e)

		(ontable p)
		(clear p)
	)
	(:goal (and
		;; core
		(clear c) (ontable e) (on c o) (on o r) (on r e)
	))
)
