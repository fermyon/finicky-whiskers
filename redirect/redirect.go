package main

import (
	"fmt"
	"os"
)

func main() {
	dest := os.Getenv("DESTINATION")
	fmt.Printf("status: 302\nlocation: %s\n\n", dest)
}
