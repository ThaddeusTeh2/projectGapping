
import argparse
import json
import os
from typing import Any, Dict, Iterable, List, Tuple

import firebase_admin
from firebase_admin import credentials, firestore


def _load_json(path: str) -> Any:
	with open(path, "r", encoding="utf-8") as f:
		return json.load(f)


def _iter_seed_items(seed_pack: Dict[str, Any]) -> Iterable[Tuple[str, str, Dict[str, Any]]]:
	"""Yields (collection_name, doc_id, doc_data) from a seed pack.

	Expected shape:
	  {
		"meta": {...},
		"motorcycles": [{"id": "bike_001", "data": {...}}, ...],
		"listings":   [{"id": "listing_001", "data": {...}}, ...],
		...
	  }
	"""

	for collection_name, records in seed_pack.items():
		if collection_name == "meta":
			continue
		if not isinstance(records, list):
			raise ValueError(
				f"Collection '{collection_name}' must be a list, got {type(records).__name__}"
			)
		for record in records:
			if not isinstance(record, dict):
				raise ValueError(
					f"Record in '{collection_name}' must be an object, got {type(record).__name__}"
				)
			doc_id = record.get("id")
			doc_data = record.get("data")
			if not doc_id or not isinstance(doc_id, str):
				raise ValueError(f"Record in '{collection_name}' missing string 'id': {record}")
			if not isinstance(doc_data, dict):
				raise ValueError(
					f"Record '{collection_name}/{doc_id}' missing object 'data': {record}"
				)
			yield collection_name, doc_id, doc_data


def _chunked(items: List[Any], chunk_size: int) -> Iterable[List[Any]]:
	for i in range(0, len(items), chunk_size):
		yield items[i : i + chunk_size]


def seed_firestore(
	*,
	service_account_path: str,
	seed_pack_path: str,
	batch_size: int = 450,
	dry_run: bool = False,
	merge: bool = True,
) -> None:
	if not os.path.exists(service_account_path):
		raise FileNotFoundError(f"Service account JSON not found: {service_account_path}")
	if not os.path.exists(seed_pack_path):
		raise FileNotFoundError(f"Seed pack JSON not found: {seed_pack_path}")

	cred = credentials.Certificate(service_account_path)
	try:
		firebase_admin.get_app()
	except ValueError:
		firebase_admin.initialize_app(cred)

	db = firestore.client()
	seed_pack = _load_json(seed_pack_path)
	if not isinstance(seed_pack, dict):
		raise ValueError(f"Seed pack must be a JSON object, got {type(seed_pack).__name__}")

	items = list(_iter_seed_items(seed_pack))
	if not items:
		print("No seed items found (nothing to write).")
		return

	print(f"Loaded {len(items)} documents from seed pack.")
	if dry_run:
		collections = sorted({c for (c, _, _) in items})
		print(f"Dry run: would write to collections: {', '.join(collections)}")
		return

	written = 0
	for group in _chunked(items, batch_size):
		batch = db.batch()
		for collection_name, doc_id, doc_data in group:
			doc_ref = db.collection(collection_name).document(doc_id)
			batch.set(doc_ref, doc_data, merge=merge)
		batch.commit()
		written += len(group)
		print(f"Committed batch: {written}/{len(items)}")

	print("Database seeding complete.")


def main() -> None:
	parser = argparse.ArgumentParser(description="Seed Firestore from seed_pack.json")
	parser.add_argument(
		"--service-account",
		default=os.path.join(os.path.dirname(__file__), "serviceAccountKey.json"),
		help="Path to Firebase service account JSON",
	)
	parser.add_argument(
		"--seed-pack",
		default=os.path.join(os.path.dirname(__file__), "seed_pack.json"),
		help="Path to seed pack JSON",
	)
	parser.add_argument(
		"--batch-size",
		type=int,
		default=450,
		help="Firestore batch size (max 500; leave headroom)",
	)
	parser.add_argument(
		"--no-merge",
		action="store_true",
		help="Disable merge (overwrite documents instead of upsert/merge)",
	)
	parser.add_argument(
		"--dry-run",
		action="store_true",
		help="Validate input and print what would happen without writing",
	)
	args = parser.parse_args()

	seed_firestore(
		service_account_path=args.service_account,
		seed_pack_path=args.seed_pack,
		batch_size=max(1, min(500, args.batch_size)),
		dry_run=args.dry_run,
		merge=not args.no_merge,
	)


if __name__ == "__main__":
	main()
