import unittest

import scripts.enrich_spec as enrich_spec


class ApplyRequestBodyPatchesTests(unittest.TestCase):
    def _spec_with_component(self, post_op: dict) -> dict:
        return {
            "paths": {
                "/workspaces/{workspace}/projects": {"post": post_op},
            },
            "components": {
                "requestBodies": {
                    "project": {
                        "content": {
                            "application/json": {
                                "schema": {"$ref": "#/components/schemas/project"}
                            }
                        }
                    }
                }
            },
        }

    def test_injects_missing_body_from_component(self):
        spec = self._spec_with_component({"operationId": "createAProjectInAWorkspace"})
        applied = enrich_spec.apply_request_body_patches(spec)
        self.assertEqual(applied, 1)
        rb = spec["paths"]["/workspaces/{workspace}/projects"]["post"]["requestBody"]
        self.assertEqual(rb, {"$ref": "#/components/requestBodies/project"})

    def test_does_not_overwrite_existing_body(self):
        existing = {"content": {"application/json": {"schema": {"type": "object"}}}}
        spec = self._spec_with_component(
            {"operationId": "createAProjectInAWorkspace", "requestBody": existing}
        )
        applied = enrich_spec.apply_request_body_patches(spec)
        self.assertEqual(applied, 0)
        self.assertEqual(
            spec["paths"]["/workspaces/{workspace}/projects"]["post"]["requestBody"],
            existing,
        )

    def test_skips_when_referenced_component_absent(self):
        # No components/requestBodies/project — must not create a dangling ref.
        spec = {
            "paths": {
                "/workspaces/{workspace}/projects": {
                    "post": {"operationId": "createAProjectInAWorkspace"}
                }
            },
            "components": {"requestBodies": {}},
        }
        applied = enrich_spec.apply_request_body_patches(spec)
        self.assertEqual(applied, 0)
        self.assertNotIn(
            "requestBody",
            spec["paths"]["/workspaces/{workspace}/projects"]["post"],
        )


if __name__ == "__main__":
    unittest.main()
