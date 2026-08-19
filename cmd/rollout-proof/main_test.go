package main

import (
	"bytes"
	"os/exec"
	"testing"
)

func TestEntryPointRunsWithoutBuildMetadata(t *testing.T) {
	t.Parallel()

	command := exec.Command("go", "run", ".")
	var stdout bytes.Buffer
	var stderr bytes.Buffer
	command.Stdout = &stdout
	command.Stderr = &stderr

	if err := command.Run(); err != nil {
		t.Fatalf("run entrypoint: %v; stderr: %s", err, stderr.String())
	}
	if stdout.Len() != 0 {
		t.Fatalf("unexpected stdout: %q", stdout.String())
	}
	if stderr.Len() != 0 {
		t.Fatalf("unexpected stderr: %q", stderr.String())
	}
}
