define i8 @main(i8 %argc, i8** %arcv) {
  %1 = sub nsw i8 124, -8
  ret i8 %1
}
; ASSERT POISON: call i8 @main(i8 1, i8** null)
