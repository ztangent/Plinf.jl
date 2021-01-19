(define (problem block_words)
	(:domain block-words)
	(:objects
		d r a w p e - block
	)
	(:init
		(handempty)

		(clear r)
		(ontable r)

		(clear a)
		(on a p)
		(on p w)
		(ontable w)

		(clear e)
		(on e d)
		(ontable d)
	)
	(:goal (and
		;; pear
		(clear p) (ontable r) (on p e) (on e a) (on a r)
	))
)
