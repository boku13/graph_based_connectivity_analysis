"""
RTL Connectivity Analysis Tool
Main entry point for analyzing Verilog RTL designs
"""

import os
import sys
import argparse
from pathlib import Path
from typing import List, Dict
import json

from verilog_parser import parse_verilog_file
from graph_builder import build_dependency_graph
from report_generator import ReportGenerator


class RTLConnectivityAnalyzer:
    """Main tool for RTL connectivity analysis"""
    
    def __init__(self, top_k: int = 10):
        self.top_k = top_k
        self.results = []
    
    def analyze_file(self, verilog_file: str, output_dir: str = None) -> Dict:
        """Analyze a single Verilog file"""
        print(f"\nAnalyzing: {verilog_file}")
        
        try:
            # Parse Verilog file
            module_name, signals, dependencies = parse_verilog_file(verilog_file)
            
            # Build dependency graph
            graph = build_dependency_graph(module_name, signals, dependencies)
            
            print(f"  Module: {module_name}")
            print(f"  Signals: {len(signals)}")
            print(f"  Dependencies: {graph.graph.number_of_edges()}")
            
            # Generate reports
            if output_dir:
                os.makedirs(output_dir, exist_ok=True)
                
                # Text report
                text_report = os.path.join(output_dir, f"{module_name}_analysis.txt")
                report_gen = ReportGenerator(graph)
                report_gen.generate_text_report(text_report, self.top_k)
                print(f"  Text report: {text_report}")
                
                # JSON report
                json_report = os.path.join(output_dir, f"{module_name}_analysis.json")
                report_gen.generate_json_report(json_report, self.top_k)
                print(f"  JSON report: {json_report}")
                
                # Summary
                summary = report_gen.generate_summary_report()
                print(f"  Summary: {summary}")
            
            # Store results
            stats = graph.get_statistics()
            result = {
                'file': verilog_file,
                'module': module_name,
                'statistics': stats,
                'top_fan_in': graph.get_top_k_fan_in(self.top_k),
                'top_fan_out': graph.get_top_k_fan_out(self.top_k)
            }
            self.results.append(result)
            
            return result
            
        except Exception as e:
            print(f"  ERROR: {str(e)}")
            import traceback
            traceback.print_exc()
            return None
    
    def analyze_dataset(self, manifest_file: str, output_base_dir: str = "analysis_reports") -> None:
        """Analyze all designs in a dataset manifest"""
        print("=" * 80)
        print("RTL CONNECTIVITY ANALYSIS TOOL")
        print("=" * 80)
        
        # Load manifest
        with open(manifest_file, 'r') as f:
            manifest = json.load(f)
        
        print(f"\nDataset: {manifest['dataset_name']}")
        print(f"Total Designs: {len(manifest['designs'])}")
        print(f"Top-K: {self.top_k}")
        
        # Analyze each design
        for design in manifest['designs']:
            design_name = design['name']
            verilog_file = design['rtl_file']
            
            if not os.path.exists(verilog_file):
                print(f"\nSkipping {design_name}: File not found - {verilog_file}")
                continue
            
            # Create output directory for this design
            output_dir = os.path.join(output_base_dir, design_name)
            
            # Analyze
            self.analyze_file(verilog_file, output_dir)
        
        # Generate summary report
        self._generate_dataset_summary(output_base_dir, manifest)
        
        print("\n" + "=" * 80)
        print("ANALYSIS COMPLETE")
        print("=" * 80)
    
    def _generate_dataset_summary(self, output_dir: str, manifest: Dict) -> None:
        """Generate a summary report for the entire dataset"""
        summary_file = os.path.join(output_dir, "dataset_summary.txt")
        
        with open(summary_file, 'w') as f:
            f.write("=" * 80 + "\n")
            f.write("DATASET SUMMARY REPORT\n")
            f.write("=" * 80 + "\n")
            f.write(f"Dataset: {manifest['dataset_name']}\n")
            f.write(f"Total Designs: {len(manifest['designs'])}\n")
            f.write(f"Top-K: {self.top_k}\n\n")
            
            f.write("Design Statistics:\n")
            f.write("-" * 80 + "\n")
            f.write(f"{'Module':<30} {'Signals':<10} {'Deps':<10} {'Avg FI':<10} {'Avg FO':<10}\n")
            f.write("-" * 80 + "\n")
            
            for result in self.results:
                if result:
                    stats = result['statistics']
                    f.write(f"{stats['module_name']:<30} "
                          f"{stats['total_signals']:<10} "
                          f"{stats['total_dependencies']:<10} "
                          f"{stats['average_fan_in']:<10.2f} "
                          f"{stats['average_fan_out']:<10.2f}\n")
            
            f.write("\n")
            
            # Top signals across all designs
            f.write("=" * 80 + "\n")
            f.write("NOTABLE SIGNALS ACROSS ALL DESIGNS\n")
            f.write("=" * 80 + "\n\n")
            
            for result in self.results:
                if result and (result['top_fan_in'] or result['top_fan_out']):
                    f.write(f"\nModule: {result['module']}\n")
                    f.write("-" * 40 + "\n")
                    
                    if result['top_fan_in']:
                        top = result['top_fan_in'][0]
                        f.write(f"  Highest Fan-In: {top[0]} (count: {top[1]})\n")
                    
                    if result['top_fan_out']:
                        top = result['top_fan_out'][0]
                        f.write(f"  Highest Fan-Out: {top[0]} (count: {top[1]})\n")
        
        print(f"\nDataset summary: {summary_file}")


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='RTL Connectivity Analysis Tool for Verilog Designs',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    
    parser.add_argument('input', 
                       help='Input Verilog file or manifest JSON file')
    
    parser.add_argument('-o', '--output', 
                       default='analysis_reports',
                       help='Output directory for reports (default: analysis_reports)')
    
    parser.add_argument('-k', '--top-k', 
                       type=int, 
                       default=10,
                       help='Number of top signals to report (default: 10)')
    
    parser.add_argument('-m', '--manifest',
                       action='store_true',
                       help='Input is a manifest file (analyze multiple designs)')
    
    args = parser.parse_args()
    
    # Create analyzer
    analyzer = RTLConnectivityAnalyzer(top_k=args.top_k)
    
    if args.manifest:
        # Analyze dataset from manifest
        analyzer.analyze_dataset(args.input, args.output)
    else:
        # Analyze single file
        analyzer.analyze_file(args.input, args.output)


if __name__ == '__main__':
    main()
